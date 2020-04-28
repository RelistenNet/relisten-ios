//
//  RelistenDb.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/21/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation
import SQLite
import Crashlytics
import SwiftyJSON

public struct RelistenDbShowDocument {
    public let show: ShowWithSources
    public let artist: ArtistWithCounts
    
    public func toJSON() -> [String: Any] {
        return [
            "show": show.originalJSON.dictionaryObject!,
            "artist": artist.originalJSON.dictionaryObject!
        ]
    }
}

public enum RelistenDbError : Error {
    case initingFromDocument
}

public class RelistenDbVenue: VenueCellDataSource {
    public let name: String
    public let location: String
    public let past_names: String?
    
    public required init?(fromJSON j: JSON) {
        guard
            let name = j["name"].string,
            let location = j["location"].string
        else {
            return nil
        }
        
        self.name = name
        self.location = location
        self.past_names = j["past_names"].string
    }
}

public class RelistenDbTour: TourCellDataSource {
    public let name: String
    public let start_date: Date
    public let end_date: Date

    public required init?(fromJSON j: JSON) {
        guard
            let name = j["name"].string,
            let start_date = j["start_date"].dateTime,
            let end_date = j["end_date"].dateTime
        else {
            return nil
        }
        
        self.start_date = start_date
        self.end_date = end_date
        self.name = name
    }
}

public class RelistenDbShow: ShowCellDataSource {
    public let uuid: UUID
    
    public let artist_id: Int
    
    public let display_date: String
    public let avg_rating: Float
    public let avg_duration: TimeInterval?
    public let most_recent_source_updated_at: Date
    public let has_soundboard_source: Bool
    public let source_count: Int
    public let date: Date
    
    public let venueDataSource: VenueCellDataSource?
    public let tourDataSource: TourCellDataSource?
    public let sourceDataSource: SourceCellDataSource?
    public let artistDataSource: ArtistWithCounts?

    public required init(fromJSON j: JSON) throws {
        guard
            let uuid = j["uuid"].uuid,
            let display_date = j["display_date"].string,
            let date = j["date"].dateTime,
            let most_recent_source_updated_at = j["most_recent_source_updated_at"].dateTime
        else {
            throw RelistenDbError.initingFromDocument
        }
        
        artist_id = try j["artist_id"].int.required()
        avg_rating = try j["avg_rating"].float.required()
        avg_duration = j["avg_duration"].double
        has_soundboard_source = try j["has_soundboard_source"].bool.required()
        source_count = try j["source_count"].int.required()
        
        self.date = date
        self.uuid = uuid
        self.display_date = display_date
        self.most_recent_source_updated_at = most_recent_source_updated_at
        self.venueDataSource = RelistenDbVenue(fromJSON: j["venue"])
        self.tourDataSource = RelistenDbTour(fromJSON: j["tour"])
        self.sourceDataSource = nil
        self.artistDataSource = RelistenCacher.artistFromCache(forId: artist_id)
    }
}

public class RelistenDb {
    public let artistsTable: SQLite.Table
    public let showsTable: SQLite.Table
    public let db: SQLite.Connection
    
    public static let shared = RelistenDb()

    private init() {
        let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        db = try! SQLite.Connection(documentsFolder.appendingPathComponent("relisten.sqlite").path)
        
        artistsTable = SQLite.Table("artists")
        showsTable = SQLite.Table("shows")
        
        create(table: artistsTable)
        create(table: showsTable)
    }
    
    func logError(_ error: Error, userInfo: [String: Any]) {
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
        LogError("Database error (\(error) with user info: \(userInfo)")
    }
    
    let idColumn = SQLite.Expression<String>("id")
    let dataColumn = SQLite.Expression<String>("data")

    func jsonExtract<T>(keyPath: String) -> SQLite.Expression<T> where T: SQLite.Binding {
        return SQLite.Expression("json_extract(\(dataColumn.template), ?)", dataColumn.bindings + ["$." + keyPath])
    }

    func jsonExtractFilter<T>(keyPath: String, _ value: T) -> SQLite.Expression<Bool?> where T: SQLite.Binding {
        return SQLite.Expression("json_extract(\(dataColumn.template), ?) = ?", dataColumn.bindings + ["$." + keyPath, value])
    }

    func create(table: SQLite.Table) {
        do {
            try db.run(table.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: true)
                t.column(dataColumn)
            })
        }
        catch {
            logError(error, userInfo: ["action": "create_table"])
        }
    }
    
    func store(table: SQLite.Table, id: String, _ json: [String: Any]) throws {
        let jsonString = String(data: try JSONSerialization.data(withJSONObject: json), encoding: .utf8)!
        
        let insert = table.insert(or: .replace, idColumn <- id, dataColumn <- jsonString)
        
        try db.run(insert)
    }
    
    func fetch(table: SQLite.Table, id: String) throws -> JSON? {
        let query = table.select([idColumn, dataColumn])
             .filter(idColumn == id)
             .limit(1)
        
        let row = try db.pluck(query)
        
        guard let r = row else {
            return nil
        }
        
        return JSON(parseJSON: r[dataColumn])
    }
    
    func fetch<T>(table: SQLite.Table, keyPath: String, _ value: T) throws -> JSON? where T: SQLite.Binding {
        let query = table.select([idColumn, dataColumn])
             .filter(jsonExtractFilter(keyPath: keyPath, value))
             .limit(1)
        
        let row = try db.pluck(query)
        
        guard let r = row else {
            return nil
        }
        
        return JSON(parseJSON: r[dataColumn])
    }
    
    public func cache(show: ShowWithSources) {
        do {
            if let a = artist(byId: show.artist_id) {
                let data = RelistenDbShowDocument(show: show, artist: a).toJSON()
                
                try store(table: showsTable, id: show.uuid.uuidString, data)
            } else {
                LogError("Unable to find artist: id=\(show.artist_id)")
            }
        } catch {
            logError(error, userInfo: ["artist_id": show.artist_id])
        }
    }
    
    public func cache(artists: [ArtistWithCounts]) {
        do {
            try db.transaction {
                for artist in artists {
                    let data = artist.originalJSON.dictionaryObject!
                    
                    try store(table: artistsTable, id: artist.uuid.uuidString, data)
                }
            }
        } catch {
            logError(error, userInfo: ["artist_uuids": artists.map { $0.uuid }])
        }
    }
    
    public func artist(byId artist_id: Int) -> ArtistWithCounts? {
        do {
            if let json = try fetch(table: artistsTable, keyPath: "id", artist_id) {
                return try ArtistWithCounts(json: json)
            }
        } catch {
            logError(error, userInfo: ["artist_id": artist_id])
        }
        
        return nil
    }
    
    public func artist(byUUID artist_uuid: UUID) -> ArtistWithCounts? {
        do {
            if let json = try fetch(table: artistsTable, id: artist_uuid.uuidString) {
                return try ArtistWithCounts(json: json)
            }
        } catch {
            logError(error, userInfo: ["artist_uuid": artist_uuid.uuidString])
        }
        
        return nil
    }
    
    public func show(byUUID show_uuid: UUID) -> ShowWithSources? {
        do {
            if let json = try fetch(table: showsTable, id: show_uuid.uuidString)  {
                return try ShowWithSources(json: json["show"])
            }
        } catch {
            logError(error, userInfo: ["show_uuid": show_uuid.uuidString])
        }
        
        return nil
    }
    
    func cellShowsQuery(forUUIDs uuids: [UUID]) -> SQLite.QueryType {
        let uuidStrs = uuids.map { $0.uuidString }
        
        return showsTable
            .select([idColumn, dataColumn])
            .filter(uuidStrs.contains(idColumn))
    }
    
    public func cellShows(byUUIDs uuids: [UUID]) -> [RelistenDbShow] {
        do {
            let query = cellShowsQuery(forUUIDs: uuids)
            
            var results = Array(try db.prepare(query))
            
            // if we are missing some results, try to pull them from the old cache
            let dbUuids = Set(try results.map { UUID(uuidString: try $0.get(idColumn))! })
            let missing = Set(uuids).subtracting(dbUuids)

            if missing.count > 0 {
                // this will trigger them to be inserted into the new cache
                missing.forEach { let _ = RelistenCacher.showFromCache(forUUID: $0) }
                
                let q = cellShowsQuery(forUUIDs: Array(missing))
                let res = Array(try db.prepare(q))
                
                results.append(contentsOf: res)
            }
            
            return try results.map { row in
                let json = JSON(parseJSON: row[dataColumn])
                return try RelistenDbShow(fromJSON: json["show"])
            }
        } catch {
            logError(error, userInfo: ["show_uuids": uuids.map { $0.uuidString }])
        }
        
        return []
    }
}
