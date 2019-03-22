//
//  RelistenDb.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/21/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
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
    internal static let DbKeys = ["venue.name", "venue.location", "venue.past_names"]
    
    public let name: String
    public let location: String
    public let past_names: String?
    
    public required init?(fromResult d: Result) {
        guard
            let name = d.string(forKey: "venue.name"),
            let location = d.string(forKey: "venue.location")
        else {
            return nil
        }
        
        self.name = name
        self.location = location
        self.past_names = d.string(forKey: "venue.past_names")
    }
}

public class RelistenDbTour: TourCellDataSource {
    internal static let DbKeys = ["tour.name", "tour.start_date", "tour.end_date"]

    public let name: String
    public let start_date: Date
    public let end_date: Date

    public required init?(fromResult d: Result) {
        guard
            let name = d.string(forKey: "tour.name"),
            let start_date = d.date(forKey: "tour.start_date"),
            let end_date = d.date(forKey: "tour.end_date")
        else {
            return nil
        }
        
        self.start_date = start_date
        self.end_date = end_date
        self.name = name
    }
}

public class RelistenDbShow: ShowCellDataSource {
    internal static let DbKeys = [
        "uuid", "artist_id", "display_date", "avg_rating", "avg_duration", "date",
        "most_recent_source_updated_at", "has_soundboard_source", "source_count"
    ] + RelistenDbVenue.DbKeys + RelistenDbTour.DbKeys
    
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

    public required init(fromResult d: Result) throws {
        guard
            let uuidStr = d.string(forKey: "uuid"),
            let uuid = UUID(uuidString: uuidStr),
            let display_date = d.string(forKey: "display_date"),
            let date = d.date(forKey: "date"),
            let most_recent_source_updated_at = d.date(forKey: "most_recent_source_updated_at")
        else {
            throw RelistenDbError.initingFromDocument
        }
        
        artist_id = d.int(forKey: "artist_id")
        avg_rating = d.float(forKey: "avg_rating")
        avg_duration = d.contains(key: "avg_duration") ? d.double(forKey: "avg_duration") : nil
        has_soundboard_source = d.boolean(forKey: "has_soundboard_source")
        source_count = d.int(forKey: "source_count")
        
        self.date = date
        self.uuid = uuid
        self.display_date = display_date
        self.most_recent_source_updated_at = most_recent_source_updated_at
        self.venueDataSource = RelistenDbVenue(fromResult: d)
        self.tourDataSource = RelistenDbTour(fromResult: d)
        self.sourceDataSource = nil
        self.artistDataSource = RelistenCacher.artistFromCache(forId: artist_id)
    }
}

extension ResultSet {
    func firstDictionary() -> [String: Any]? {
        return allResults().first?.toDictionary().values.first as? [String: Any]
    }
}

public class RelistenDb {
    public let artistsDb: CouchbaseLiteSwift.Database
    public let showsDb: CouchbaseLiteSwift.Database
    
    public static let shared = RelistenDb()

    private init() {
        let config = DatabaseConfiguration()
        config.directory = PersistentCacheDirectory.path
        
        artistsDb = try! Database(name: "artists", config: config)
        showsDb = try! Database(name: "shows", config: config)
    }
    
    func logError(_ error: Error, userInfo: [String: Any]) {
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
        LogError("Database error (\(error) with user info: \(userInfo)")
    }
    
    public func cache(show: ShowWithSources) {
        do {
            if let a = artist(byId: show.artist_id) {
                let data = RelistenDbShowDocument(show: show, artist: a).toJSON()
                
                let showDoc = MutableDocument(id: show.uuid.uuidString, data: data)
                
                try showsDb.saveDocument(showDoc)
            } else {
                LogError("Unable to find artist: id=\(show.artist_id)")
            }
        } catch {
            logError(error, userInfo: ["artist_id": show.artist_id])
        }
    }
    
    public func cache(artists: [ArtistWithCounts]) {
        do {
            try self.artistsDb.inBatch {
                for artist in artists {
                    let data = artist.originalJSON.dictionaryObject!
                    let artistDoc = MutableDocument(id: artist.uuid.uuidString, data: data)
                    
                    try artistsDb.saveDocument(artistDoc)
                }
            }
        } catch {
            logError(error, userInfo: ["artist_uuids": artists.map { $0.uuid }])
        }
    }
    
    public func artist(byId artist_id: Int) -> ArtistWithCounts? {
        do {
            let query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(artistsDb))
                .where(Expression.property("id").equalTo(Expression.int(artist_id)))
                .limit(Expression.int(1))

            if let doc = try query.execute().firstDictionary() {
                return try ArtistWithCounts(json: JSON(doc))
            }
        } catch {
            logError(error, userInfo: ["artist_id": artist_id])
        }
        
        return nil
    }
    
    public func artist(byUUID artist_uuid: UUID) -> ArtistWithCounts? {
        do {
            let query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(artistsDb))
                .where(Meta.id.equalTo(Expression.string(artist_uuid.uuidString)))
                .limit(Expression.int(1))
            
            if let doc = try query.execute().firstDictionary() {
                return try ArtistWithCounts(json: JSON(doc))
            }
        } catch {
            logError(error, userInfo: ["artist_uuid": artist_uuid.uuidString])
        }
        
        return nil
    }
    
    public func show(byUUID show_uuid: UUID) -> ShowWithSources? {
        do {
            let query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(showsDb))
                .where(Meta.id.equalTo(Expression.string(show_uuid.uuidString)))
                .limit(Expression.int(1))
            
            if let doc = try query.execute().firstDictionary(), let showDict = doc["show"] {
                return try ShowWithSources(json: JSON(showDict))
            }
        } catch {
            logError(error, userInfo: ["show_uuid": show_uuid.uuidString])
        }
        
        return nil
    }
    
    public func cellShows(byUUIDs uuids: [UUID]) -> [RelistenDbShow] {
        do {
            let query = QueryBuilder
                .select(RelistenDbShow.DbKeys.map { SelectResult.property("show." + $0).as($0) })
                .from(DataSource.database(showsDb))
                .where(Meta.id.in(uuids.map { Expression.string($0.uuidString) }))
            
            let resultSet = try query.execute()
            let results = resultSet.allResults()
            
            return try results.map { try RelistenDbShow(fromResult: $0) }
        } catch {
            logError(error, userInfo: ["show_uuids": uuids.map { $0.uuidString }])
        }
        
        return []
    }
}
