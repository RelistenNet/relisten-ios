//
//  OfflineSourceMetadata.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/18/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import RealmSwift

public protocol FavoritedItem {
    var uuid: UUID! { get set }
    var created_at: Date! { get set }
}

public class FavoritedArtist : Object, FavoritedItem {
    @objc public dynamic var uuid: UUID!
    @objc public dynamic var created_at: Date!

    @objc public dynamic var artist_uuid: UUID! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
}

public class FavoritedShow: Object, FavoritedItem {
    @objc public dynamic var uuid: UUID!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var show_date: Date!
    @objc public dynamic var artist_uuid: UUID!
    
    @objc public dynamic var show_uuid: UUID! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid"]
    }
}

public class FavoritedSource: Object, FavoritedItem {
    @objc public dynamic var uuid: UUID!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var artist_uuid: UUID!
    @objc public dynamic var show_uuid: UUID!
    @objc public dynamic var show_date: Date!

    @objc public dynamic var source_uuid: UUID! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
    
    private var _show: ShowWithSources? = nil
    public var show: ShowWithSources {
        get {
            if let s = _show {
                return s
            }
            
            let s = try! RelistenShowCacher.shared.backingCache.object(forKey: show_uuid.uuidString)
            _show = s
            
            return s
        }
    }
    
    public var source: SourceFull {
        get {
            return show.sources.first(where: { $0.uuid == source_uuid })!
        }
    }
}

public class FavoritedTrack: Object, FavoritedItem {
    @objc public dynamic var uuid: UUID!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var artist_uuid: UUID!

    @objc public dynamic var track_uuid: UUID! { get { return uuid }}

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
}

public class RecentlyPlayedShow: Object {
    @objc public dynamic var show_uuid: UUID!
    @objc public dynamic var source_uuid: UUID!
    @objc public dynamic var artist_uuid: UUID!

    @objc public dynamic var created_at: Date!
    @objc public dynamic var updated_at: Date!

    public override static func primaryKey() -> String? {
        return "show_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "artist_uuid"]
    }
    
    private var _show: ShowWithSources? = nil
    public var show: ShowWithSources {
        get {
            if let s = _show {
                return s
            }
            
            let s = try! RelistenShowCacher.shared.backingCache.object(forKey: show_uuid.uuidString)
            _show = s
            
            return s
        }
    }
    
    public var source: SourceFull {
        get {
            return show.sources.first(where: { $0.uuid == source_uuid })!
        }
    }
}

public class TrackLookup: Object {
    @objc public dynamic var track_uuid: UUID!
    @objc public dynamic var source_uuid: UUID!
    @objc public dynamic var show_uuid: UUID!
    @objc public dynamic var artist_uuid: UUID!

    public override static func primaryKey() -> String? {
        return "track_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "show_uuid", "artist_uuid"]
    }
}

public class OfflineTrack: Object {
    @objc public dynamic var track_uuid: UUID!
    @objc public dynamic var source_uuid: UUID!
    @objc public dynamic var show_uuid: UUID!
    @objc public dynamic var artist_uuid: UUID!
    @objc public dynamic var created_at: Date!

    // Realm doesn't support UInt64
    public let file_size = RealmOptional<Int>()
    
    public override static func primaryKey() -> String? {
        return "track_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "show_uuid", "artist_uuid"]
    }
}

public class OfflineSource: Object {
    @objc public dynamic var source_uuid: UUID!
    @objc public dynamic var show_uuid: UUID!
    @objc public dynamic var artist_uuid: UUID!
    @objc public dynamic var year_uuid: UUID!
    @objc public dynamic var created_at: Date!

    public override static func primaryKey() -> String? {
        return "source_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid", "artist_uuid", "year_uuid"]
    }
}

public struct PlaybackRestoration : Codable {
    public let queue: [UUID] = [] // track UUIDs
    public let active: UUID? = nil // active track UUID
    public let playbackPosition: TimeInterval? = nil // position in active track
    public let playbackState: Track.PlaybackState = .notActive
}

public struct OfflineSourceMetadata : Codable, Hashable {
    public var hashValue: Int {
        return completeShowInformation.hashValue
    }
    
    public static func == (lhs: OfflineSourceMetadata, rhs: OfflineSourceMetadata) -> Bool {
        return lhs.completeShowInformation == rhs.completeShowInformation
    }
    
    public var year: String {
        let yearEnd = completeShowInformation.show.display_date.index(completeShowInformation.show.display_date.startIndex, offsetBy: 4)
        return String(completeShowInformation.show.display_date[..<yearEnd])
    }
    
    public var show: Show {
        return completeShowInformation.show
    }
    
    public var source: SourceFull {
        return completeShowInformation.source
    }
    
    public var artist: ArtistWithCounts {
        return completeShowInformation.artist
    }
    
    public let completeShowInformation: CompleteShowInformation
    
    public let dateAdded: Date
    
    public static func from(track: Track) -> OfflineSourceMetadata {
        return self.init(completeShowInformation: track.showInfo, dateAdded: Date())
    }
    
    private enum CodingKeys: String, CodingKey {
        case completeShowInformation
        case dateAdded
    }
}
