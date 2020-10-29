//
//  OfflineSourceMetadata.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/18/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import RealmSwift
import Realm
import Crashlytics

@objc public protocol HasArtist {
    @objc var artist_uuid: String { get }
}

@objc public protocol HasShow : HasArtist {
    @objc var show_uuid: String { get }
}

@objc public protocol HasSourceAndShow : HasShow {
    @objc var source_uuid: String { get }
}

@objc public protocol HasTrackSourceAndShow : HasSourceAndShow {
    @objc var track_uuid: String { get }
}

public extension HasArtist {
    var artist: ArtistWithCounts? {
        get {
            return RelistenCacher.artistFromCache(forUUID: UUID(uuidString: artist_uuid)!)
        }
    }
}

public extension HasShow {
    var show: ShowWithSources? {
        get {
            return RelistenCacher.showFromCache(forUUID: UUID(uuidString: show_uuid)!)
        }
    }
}

public extension HasSourceAndShow {
    var source: SourceFull? {
        get {
            return show?.sources.first(where: { $0.uuid.uuidString == source_uuid })
        }
    }
    
    var completeShowInformation: CompleteShowInformation? {
        get {
            if let show = self.show,
               let art = artist,
               let source = show.sources.first(where: { $0.uuid.uuidString == source_uuid }) {
                return CompleteShowInformation(source: source, show: show, artist: art)
            }
            return nil
        }
    }
}

public extension HasTrackSourceAndShow {
    var sourceTrack: SourceTrack? {
        get {
            return source?.track(withUUID: track_uuid)
        }
    }
    
    var track: Track? {
        get {
            if let completeShowInformation = completeShowInformation,
               let sourceTrack = completeShowInformation.source.track(withUUID: track_uuid) {
                return Track(sourceTrack: sourceTrack, showInfo: completeShowInformation)
            }
            return nil
        }
    }
}

public extension Results where Element : HasTrackSourceAndShow {
    func asTracks(toIndex index: Int = 20) -> [Track] {
        return Array(self.array(toIndex: index).compactMap({ (el: HasTrackSourceAndShow) -> Track? in el.track }))
    }
    
    func asTracksLazy() -> LazyMapCollection<LazyFilterCollection<LazyMapCollection<Results<Element>, Track?>>, Track> {
        return compactMap({ (el: HasTrackSourceAndShow) -> Track? in el.track })
    }
}

public extension Results where Element : HasSourceAndShow {
    func asCompleteShows(toIndex index: Int = 20) -> [CompleteShowInformation] {
        return Array(self.array(toIndex: index).compactMap({ (el: HasSourceAndShow) -> CompleteShowInformation? in el.completeShowInformation }))
    }
    
    func asCompleteShowsLazy() -> LazyMapCollection<LazyFilterCollection<LazyMapCollection<Results<Element>, CompleteShowInformation?>>, CompleteShowInformation> {
        return compactMap({ (el: HasSourceAndShow) -> CompleteShowInformation? in el.completeShowInformation })
    }
}

public extension Results {
    func array(toIndex index: Int = -1) -> [Element] {
        if index == -1 {
            return Array(self)
        } else {
            var results : [Element] = []
            let maxResults = Swift.min(index, self.count)
            for i in (0..<maxResults) {
                results.append(self[i])
            }
            return results
        }
    }
    
    func observeWithValue(_ block: @escaping (Results<Element>, RealmCollectionChange<Results<Element>>) -> Void) -> NotificationToken {
        return self.observe { changes in
            block(self, changes)
        }
    }
}

public protocol FavoritedItem {
    var uuid: String { get set }
    var created_at: Date { get set }
}

public class RelistenRealmObject : Object, FavoritedItem {
    @objc public dynamic var uuid: String = UUID().uuidString
    @objc public dynamic var created_at: Date = Date()
    
    public init(uuid: String? = nil, created_at: Date? = nil) {
        if let uuid = uuid {
            self.uuid = uuid
        }
        if let created_at = created_at {
            self.created_at = created_at
        }
        super.init()
    }
    
    // Stupid useless required initializers
    public required override init() {
        super.init()
    }
}

public class FavoritedArtist : RelistenRealmObject, HasArtist {
    @objc public dynamic var artist_uuid: String { get { return uuid }}
    
    public init(artist_uuid: String) {
        super.init(uuid: artist_uuid)
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // Stupid useless required initializers
    public required init() {
        super.init()
    }
}

public class FavoritedShow: RelistenRealmObject, HasShow {
    @objc public dynamic var show_date: Date = Date()
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    
    @objc public dynamic var show_uuid: String { get { return uuid }}
    
    public init(uuid: String? = nil, show_date: Date, artist_uuid: String) {
        self.show_date = show_date
        self.artist_uuid = artist_uuid
        super.init(uuid: uuid)
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid", "show_date", "artist_uuid"]
    }
    
    // Stupid useless required initializers
    public required init() {
        super.init()
    }
}

public class FavoritedSource: RelistenRealmObject, HasSourceAndShow {
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_date: Date = Date()

    @objc public dynamic var source_uuid: String { get { return uuid }}
    
    public init(source_uuid: String, artist_uuid: String, show_uuid: String, show_date: Date) {
        self.artist_uuid = artist_uuid
        self.show_uuid = show_uuid
        self.show_date = show_date
        super.init(uuid: source_uuid)
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
    
    // Stupid useless required initializers
    public required init() {
        super.init()
    }
}

public class FavoritedTrack: RelistenRealmObject, HasTrackSourceAndShow {
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_uuid: String = "BAD_VALUE"
    @objc public dynamic var source_uuid: String = "BAD_VALUE"

    @objc public dynamic var track_uuid: String { get { return uuid }}
    
    public init(track_uuid: String, artist_uuid: String, show_uuid: String, source_uuid: String) {
        self.artist_uuid = artist_uuid
        self.show_uuid = show_uuid
        self.source_uuid = source_uuid
        super.init(uuid: track_uuid)
    }

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["artist_uuid"]
    }
    
    // Stupid useless required initializers
    public required init() {
        super.init()
    }
}

public class RecentlyPlayedTrack: RelistenRealmObject, HasTrackSourceAndShow {
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_uuid: String = "BAD_VALUE"
    @objc public dynamic var source_uuid: String = "BAD_VALUE"
    @objc public dynamic var track_uuid: String = "BAD_VALUE"
    @objc public dynamic var updated_at: Date = Date()
    @objc public dynamic var past_halfway: Bool = false
    
    public init(uuid: String? = nil, artist_uuid: String, show_uuid: String, source_uuid: String, track_uuid: String) {
        self.artist_uuid = artist_uuid
        self.show_uuid = show_uuid
        self.source_uuid = source_uuid
        self.track_uuid = track_uuid
        super.init(uuid: uuid)
    }

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "artist_uuid", "show_uuid", "tack_uuid"]
    }
    
    // Stupid useless required initializers
    public required init() {
        super.init()
    }
}

@objc public enum OfflineTrackState : Int, RealmEnum {
    case unknown
    case downloadQueued
    case downloading
    case downloaded
    case deleting
}

public class OfflineTrack: Object, HasTrackSourceAndShow {
    @objc public dynamic var track_uuid: String = UUID().uuidString // primary key
    
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_uuid: String = "BAD_VALUE"
    @objc public dynamic var source_uuid: String = "BAD_VALUE"
    
    @objc public dynamic var created_at: Date = Date()
    @objc public dynamic var state: OfflineTrackState = .unknown

    // Realm doesn't support UInt64
    public let file_size = RealmOptional<Int>()
    
    public init(track_uuid: String, artist_uuid: String, show_uuid: String, source_uuid: String, created_at : Date? = nil, state : OfflineTrackState? = .unknown, file_size : Int? = nil) {
        self.track_uuid = track_uuid
        self.artist_uuid = artist_uuid
        self.show_uuid = show_uuid
        self.source_uuid = source_uuid
        if let created_at = created_at {
            self.created_at = created_at
        }
        if let state = state {
            self.state = state
        }
        if let file_size = file_size {
            self.file_size.value = file_size
        }
        super.init()
    }
    
    public override static func primaryKey() -> String? {
        return "track_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["source_uuid", "show_uuid", "artist_uuid"]
    }
    
    // Stupid useless required initializers
    public required override init() {
        super.init()
    }
}

public class OfflineSource: Object, HasSourceAndShow {
    @objc public dynamic var source_uuid: String = UUID().uuidString // primary key
    
    @objc public dynamic var artist_uuid: String = "BAD_VALUE"
    @objc public dynamic var show_uuid: String = "BAD_VALUE"
    @objc public dynamic var year_uuid: String = "BAD_VALUE"
    
    @objc public dynamic var created_at: Date = Date()
    
    public init(source_uuid: String, artist_uuid: String, show_uuid: String, year_uuid: String, created_at : Date? = nil) {
        self.source_uuid = source_uuid
        self.artist_uuid = artist_uuid
        self.show_uuid = show_uuid
        self.year_uuid = year_uuid
        if let created_at = created_at {
            self.created_at = created_at
        }
        super.init()
    }

    public override static func primaryKey() -> String? {
        return "source_uuid"
    }
    
    public override static func indexedProperties() -> [String] {
        return ["show_uuid", "artist_uuid", "year_uuid"]
    }
    
    // Stupid useless required initializers
    public required override init() {
        super.init()
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
