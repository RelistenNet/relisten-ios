//
//  OfflineSourceMetadata.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/18/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import RealmSwift

@objc public protocol HasArtist {
    @objc var artist_uuid: String! { get }
}

@objc public protocol HasShow : HasArtist {
    @objc var show_uuid: String! { get }
}

@objc public protocol HasSourceAndShow : HasShow {
    @objc var source_uuid: String! { get }
}

@objc public protocol HasTrackSourceAndShow : HasSourceAndShow {
    @objc var track_uuid: String! { get }
}

public extension HasArtist {
    public var artist: ArtistWithCounts {
        get {
            return try! RelistenCacher.shared.artistBackingCache.object(forKey: artist_uuid)
        }
    }
}

public extension HasShow {
    public var show: ShowWithSources {
        get {
            return try! RelistenCacher.shared.showBackingCache.object(forKey: show_uuid)
        }
    }
}

public extension HasSourceAndShow {
    public var source: SourceFull? {
        get {
            return show.sources.first(where: { $0.uuid.uuidString == source_uuid })
        }
    }
    
    public var completeShowInformation: CompleteShowInformation? {
        get {
            let show = self.show
            if let source = show.sources.first(where: { $0.uuid.uuidString == source_uuid }) {
                return CompleteShowInformation(source: source, show: show, artist: artist)
            }
            return nil
        }
    }
}

public extension HasTrackSourceAndShow {
    public var sourceTrack: SourceTrack? {
        get {
            return source?.tracksFlattened.first(where: { $0.uuid.uuidString == track_uuid })
        }
    }
    
    public var track: Track? {
        get {
            if let completeShowInformation = completeShowInformation {
                if let sourceTrack = completeShowInformation.source.tracksFlattened.first(where: { $0.uuid.uuidString == track_uuid }) {
                    return Track(sourceTrack: sourceTrack, showInfo: completeShowInformation)
                }
            }
            return nil
        }
    }
}

public extension Results where Element : HasTrackSourceAndShow {
    public func asTracks() -> [Track] {
        return Array(compactMap({ (el: HasTrackSourceAndShow) -> Track? in el.track }))
    }
}

public extension Results where Element : HasSourceAndShow {
    public func asCompleteShows() -> [CompleteShowInformation] {
        return Array(compactMap({ (el: HasSourceAndShow) -> CompleteShowInformation? in el.completeShowInformation }))
    }
}

public extension Results {
    public func observeWithValue(_ block: @escaping (Results<Element>, RealmCollectionChange<Results<Element>>) -> Void) -> NotificationToken {
        return self.observe { changes in
            block(self, changes)
        }
    }
}

public protocol FavoritedItem {
    var uuid: String! { get set }
    var created_at: Date! { get set }
}

public class FavoritedArtist : Object, FavoritedItem, HasArtist {
    @objc public dynamic var uuid: String!
    @objc public dynamic var created_at: Date!

    @objc public dynamic var artist_uuid: String! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
}

public class FavoritedShow: Object, FavoritedItem, HasShow {
    @objc public dynamic var uuid: String!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var show_date: Date!
    @objc public dynamic var artist_uuid: String!
    
    @objc public dynamic var show_uuid: String! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid", "show_date", "artist_uuid"]
    }
}

public class FavoritedSource: Object, FavoritedItem, HasSourceAndShow {
    @objc public dynamic var uuid: String!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var artist_uuid: String!
    @objc public dynamic var show_uuid: String!
    @objc public dynamic var show_date: Date!

    @objc public dynamic var source_uuid: String! { get { return uuid }}
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
}

public class FavoritedTrack: Object, FavoritedItem, HasTrackSourceAndShow {
    @objc public dynamic var uuid: String!
    @objc public dynamic var created_at: Date!
    @objc public dynamic var show_uuid: String!
    @objc public dynamic var source_uuid: String!
    @objc public dynamic var artist_uuid: String!

    @objc public dynamic var track_uuid: String! { get { return uuid }}

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
}

public class RecentlyPlayedTrack: Object, HasTrackSourceAndShow {
    @objc public dynamic var uuid: String! = UUID().uuidString
    
    @objc public dynamic var show_uuid: String!
    @objc public dynamic var source_uuid: String!
    @objc public dynamic var track_uuid: String!
    @objc public dynamic var artist_uuid: String!

    @objc public dynamic var created_at: Date!
    @objc public dynamic var updated_at: Date!

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "artist_uuid", "show_uuid", "tack_uuid"]
    }
}

@objc public enum OfflineTrackState : Int {
    case unknown
    case downloadQueued
    case downloading
    case downloaded
    case deleting
}

public class OfflineTrack: Object, HasTrackSourceAndShow {
    @objc public dynamic var track_uuid: String!
    @objc public dynamic var source_uuid: String!
    @objc public dynamic var show_uuid: String!
    @objc public dynamic var artist_uuid: String!
    @objc public dynamic var created_at: Date!
    
    // default value because objc enums can't be !'d
    @objc public dynamic var state: OfflineTrackState = .unknown

    // Realm doesn't support UInt64
    public let file_size = RealmOptional<Int>()
    
    public override static func primaryKey() -> String? {
        return "track_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "show_uuid", "artist_uuid"]
    }
}

public class OfflineSource: Object, HasSourceAndShow {
    @objc public dynamic var source_uuid: String!
    @objc public dynamic var show_uuid: String!
    @objc public dynamic var artist_uuid: String!
    @objc public dynamic var year_uuid: String!
    @objc public dynamic var created_at: Date!

    public override static func primaryKey() -> String? {
        return "source_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid", "artist_uuid", "year_uuid"]
    }
}

/*
public struct PlaybackRestoration : Codable {
    public let queue: [UUID] = [] // track UUIDs
    public let active: UUID? = nil // active track UUID
    public let playbackPosition: TimeInterval? = nil // position in active track
    public let playbackState: Track.PlaybackState = .notActive
}
 */
