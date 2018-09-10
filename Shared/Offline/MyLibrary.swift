//
//  MyLibrary.swift
//  Relisten
//
//  Created by Alec Gorge on 5/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON
import Cache
import SINQ
import Observable

import RealmSwift

func ReadonlyRealmObjects<Element: Object>(_ type: Element.Type) -> Results<Element> {
    let config = Realm.Configuration.defaultConfiguration
//    config.objectTypes = [type]
    
    let realm = try! Realm(configuration: config)
    
    return realm.objects(type)
}

public class MyLibraryFavorites {
    public var artists: Results<FavoritedArtist> {
        get {
            return ReadonlyRealmObjects(FavoritedArtist.self)
        }
    }
    
    public var shows: Results<FavoritedShow> {
        get {
            return ReadonlyRealmObjects(FavoritedShow.self)
        }
    }
    
    public var sources: Results<FavoritedSource> {
        get {
            return ReadonlyRealmObjects(FavoritedSource.self)
        }
    }
    
    public func sources(byArtist artist: SlimArtist) -> Results<FavoritedSource> {
        return sources
            .filter("artist_uuid == %@", artist.uuid.uuidString)
    }
    
    public var tracks: Results<FavoritedTrack> {
        get {
            return ReadonlyRealmObjects(FavoritedTrack.self)
        }
    }
}

public typealias FullOfflineSource = (show: ShowWithSources, source: SourceFull, date_added: Date)

public class MyLibraryOffline {
    public var sources: Results<OfflineSource> {
        get {
            return ReadonlyRealmObjects(OfflineSource.self)
        }
    }
    
    public func sources(byArtist artist: SlimArtist) -> Results<OfflineSource> {
        return sources
            .filter("artist_uuid == %@", artist.uuid.uuidString)
    }
    
    public var tracks: Results<OfflineTrack> {
        get {
            return ReadonlyRealmObjects(OfflineTrack.self)
        }
    }
}

public class MyLibraryRecentlyPlayed {
    public var shows: Results<RecentlyPlayedTrack> {
        get {
            return ReadonlyRealmObjects(RecentlyPlayedTrack.self)
                .sorted(by: [SortDescriptor(keyPath: "show_uuid", ascending: true), SortDescriptor(keyPath: "updated_at", ascending: false)])
                .sorted(byKeyPath: "updated_at", ascending: false)
                .distinct(by: ["show_uuid"])
            
        }
    }
    
    public func shows(byArtist artist: SlimArtist) -> Results<RecentlyPlayedTrack> {
        return shows
            .filter("artist_uuid == %@", artist.uuid.uuidString)
    }
    
    public var tracks: Results<RecentlyPlayedTrack> {
        get {
            return ReadonlyRealmObjects(RecentlyPlayedTrack.self)
                .sorted(byKeyPath: "updated_at", ascending: false)
        }
    }
}

public class MyLibrary {
    public static let shared = MyLibrary()

    public let recent = MyLibraryRecentlyPlayed()
    public let offline = MyLibraryOffline()
    public let favorites = MyLibraryFavorites()
    
    public var downloadBacklog: [Track] = []
    
    internal let realmQueue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.library.realm")
    internal let diskUseQueue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.library.diskUse")
    
    private init() {
    }
    
    public class func migrateRealmDatabase() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                    
                    // Clear out anything with a nil value
                    self.removeObjectsWithoutRequiredProperties(migration: migration)
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
    
    private class func removeObjectsWithoutRequiredProperties(migration: Migration) {
        // If a property is changed from nullable to required, auto-migration automatically sets a fixed value (for Strings, an empty string "" is set).
        // To handle this we need to grab the properties from the old object and copy them to the new one
        // https://github.com/realm/realm-cocoa/issues/4348#issuecomment-261874485
        // Iterate through all of the classes in the database
        for objectSchema in migration.oldSchema.objectSchema {
            LogDebug("Migrating class \(objectSchema.className)")
            let className = objectSchema.className
            
            if let oldSchema = migration.oldSchema[className],
                let newSchema = migration.newSchema[className] {
                
                var newPropertiesByName : [String : Property] = [:]
                for property in newSchema.properties {
                    newPropertiesByName[property.name] = property
                }
                
                // Migrate all of the objects for each class
                migration.enumerateObjects(ofType: className) { oldObject, newObject in
                    if let oldObject = oldObject,
                       let newObject = newObject {
                        for oldProperty in oldSchema.properties {
                            // Check if the property has changed from optional to required.
                            if let newProperty = newPropertiesByName[oldProperty.name],
                               (oldProperty.isOptional && !newProperty.isOptional) {
                                // If it has changed, make sure it wasn't nil before
                                if oldObject[oldProperty.name] == nil ||
                                   oldObject[oldProperty.name] as? String == "" {
                                    LogWarn("Found object of type \(className) with a nil property for \(oldProperty.name). Deleting that object to clean up the database. Take a good look at this object 'cause it's the last time you're gonna see it! \(oldObject)")
                                    migration.delete(newObject)
                                    // We're done with this object so return from the block and handle the next object
                                    return
                                }
                                // Copy the property over from the old schema
                                newObject[oldProperty.name] = oldObject[oldProperty.name]
                            }
                        }
                    } else {
                        LogWarn("Couldn't get an old or new object for class \(className)")
                    }
                }
            } else {
                LogWarn("Couldn't get the old or new schemas")
            }
        }
    }
}

// MARK: Recently Played
extension MyLibrary {
    public func trackWasPlayed(_ track: Track) -> Bool {
        let realm = try! Realm()
        
        let recentShow = RecentlyPlayedTrack(withTrack: track)
        
        try! realm.write {
            realm.add(recentShow)
        }
        
        return true
    }
    
    public func importRecentlyPlayedShow(_ showInfo: CompleteShowInformation) -> Bool {
        let realm = try! Realm()
        
        let existingFavoritedShow = realm.objects(RecentlyPlayedTrack.self).filter("show_uuid == %@ AND source_uuid == %@", showInfo.show.uuid.uuidString, showInfo.source.uuid.uuidString).first
        
        if existingFavoritedShow == nil,
           let trackUUID = showInfo.source.tracksFlattened.first?.uuid.uuidString
        {
            let recentShow = RecentlyPlayedTrack(withShowInfo: showInfo, trackUUID: trackUUID)
            do {
                try realm.write {
                    realm.add(recentShow)
                }
            } catch {
                LogError("Error importing recently played show to Realm \(showInfo): \(error)")
            }
        }
        
        return true
    }
}

// MARK: Offline Tracks
extension MyLibrary {
    public func offlinePlayedByArtist(_ artist: SlimArtist) -> Results<OfflineSource> {
        return offline.sources
            .filter("artist_uuid == %@", artist.uuid.uuidString)
            .sorted(byKeyPath: "created_at", ascending: false)
    }
    
    public func isTrackAvailableOffline(_ track: Track) -> Bool {
        return isTrackAvailableOffline(track.sourceTrack)
    }
    
    public func isTrackAvailableOffline(_ track: SourceTrack) -> Bool {
        return offline.tracks.filter("track_uuid == %@ AND state >= %d", track.uuid.uuidString, OfflineTrackState.downloaded.rawValue).count > 0
    }
    
    public func isSourceFullyAvailableOffline(_ source: SourceFull) -> Bool {
        if sinq(source.tracksFlattened).any({ !isTrackAvailableOffline($0) }) {
            return false
        }
        
        return true
    }
    
    public func isArtistAtLeastPartiallyAvailableOffline(_ artist: SlimArtist) -> Bool {
        return offline.tracks.filter("artist_uuid == %@ AND state >= %d", artist.uuid.uuidString, OfflineTrackState.downloaded.rawValue).count > 0
    }
    
    public func isShowAtLeastPartiallyAvailableOffline(_ show: Show) -> Bool {
        return offline.tracks.filter("show_uuid == %@ AND state >= %d", show.uuid.uuidString, OfflineTrackState.downloaded.rawValue).count > 0
    }
    
    public func isSourceAtLeastPartiallyAvailableOffline(_ source: SourceFull) -> Bool {
        return offline.tracks.filter("source_uuid == %@ AND state >= %d", source.uuid.uuidString, OfflineTrackState.downloaded.rawValue).count > 0
    }
    
    public func isYearAtLeastPartiallyAvailableOffline(_ year: Year) -> Bool {
        return offline.sources.filter("year_uuid == %@", year.uuid.uuidString).count > 0
    }
}


extension MyLibrary : DownloadManagerDataSource {
    public func nextTrackToDownload() -> Track? {
        return ReadonlyRealmObjects(OfflineTrack.self)
            .filter("state == %d", OfflineTrackState.downloadQueued.rawValue)
            .sorted(byKeyPath: "created_at", ascending: true)
            .first?
            .track
    }
    
    public func tracksToDownload(_ count : Int) -> [Track]? {
        let objects = ReadonlyRealmObjects(OfflineTrack.self)
            .filter("state == %d", OfflineTrackState.downloadQueued.rawValue)
            .sorted(byKeyPath: "created_at", ascending: true)
        
        return objects[0..<min(objects.count, count)].compactMap({ $0.track })
    }
    
    public func currentlyDownloadingTracks() -> [Track]? {
        let objects = ReadonlyRealmObjects(OfflineTrack.self)
            .filter("state == %d", OfflineTrackState.downloading.rawValue)
            .sorted(byKeyPath: "created_at", ascending: true)
        
        return objects.compactMap({ $0.track })
    }
    
    public func importDownloadedTrack(_ track : Track, withSize fileSize: UInt64) {
        let realm = try! Realm()
        
        let trackMeta = OfflineTrack(withTrack: track, state: .downloaded, fileSize: Int(fileSize))
        do {
            try realm.write {
                realm.add(trackMeta)
            }
        } catch {
            LogError("Error adding downloaded track \(track) to Realm: \(error)")
        }
        
        addOfflineSourceInfoForDownloadedTrack(track)
    }

    public func offlineTrackQueuedToBacklog(_ track: Track) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .downloadQueued
            }
        } else {
            let trackMeta = OfflineTrack(withTrack: track, state: .downloadQueued)
            try! realm.write {
                realm.add(trackMeta)
            }
        }
    }
    
    public func offlineTrackBeganDownloading(_ track: Track) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .downloading
            }
        }
    }
    
    public func offlineTrackFailedDownloading(_ track: Track, error: Error?) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                realm.delete(offlineTrack)
            }
        }
    }

    private func addOfflineSourceInfoForDownloadedTrack(_ track: Track) {
        let realm = try! Realm()
        let offlineSourceQuery = realm.object(ofType: OfflineSource.self, forPrimaryKey: track.showInfo.source.uuid.uuidString)
        
        if offlineSourceQuery == nil {
            do {
                try realm.write {
                    let sourceMeta = OfflineSource(withTrack: track)
                    realm.add(sourceMeta)
                }
            } catch {
                LogError("Error adding offline source for track in Realm \(track): \(error)")
            }
        }
    }
    
    public func offlineTrackFinishedDownloading(_ track: Track, withSize fileSize: UInt64) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .downloaded
                offlineTrack.file_size.value = Int(fileSize)
            }
            
            // add the source information if it doesn't exist
            addOfflineSourceInfoForDownloadedTrack(track)
        }
    }
    
    public func offlineTrackWillBeDeleted(_ track: Track) {
        let realm = try! Realm()
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .deleting
            }
        }
        // If we didn't find a track in Realm it's ok. Someone probably just tried to delete a whole show and only some of the tracks in that show were downloaded
    }
    
    public func offlineTrackWasDeleted(_ track: Track) {
        let realm = try! Realm()
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.sourceTrack.uuid.uuidString)
        
        guard let offlineTrack = offlineTrackQuery else {
            return
        }
        
        try! realm.write {
            realm.delete(offlineTrack)
        }
        
        if !isSourceAtLeastPartiallyAvailableOffline(track.showInfo.source) {
            let offlineSourceQuery = realm.object(ofType: OfflineSource.self, forPrimaryKey: track.showInfo.source.uuid.uuidString)
            
            if let offlineSource = offlineSourceQuery {
                try! realm.write {
                    realm.delete(offlineSource)
                }
            }
        }
    }
    
    public func deleteAllTracks(_ completion : @escaping () -> Void) {
        let realm = try! Realm()
        
        let offlineTracks = realm.objects(OfflineTrack.self)
        let offlineSources = realm.objects(OfflineSource.self)
        
        try! realm.write {
            realm.delete(offlineTracks)
            realm.delete(offlineSources)
        }
        completion()
    }
}

// MARK: Favorites
extension MyLibrary {
    public func favoritedSourcesPlayedByArtist(_ artist: SlimArtist) -> Results<FavoritedSource> {
        return favorites.sources
            .filter("artist_uuid == %@", artist.uuid.uuidString)
            .sorted(byKeyPath: "show_date", ascending: false)
    }
    
    public func favoriteSource(show: CompleteShowInformation) {
        let realm = try! Realm()
        
        let favoritedSourceQuery = realm.object(ofType: FavoritedSource.self, forPrimaryKey: show.source.uuid.uuidString)
        let existingFavoriteSource = favoritedSourceQuery
        if existingFavoriteSource == nil {
            let favoritedSource = FavoritedSource(withShowInfo: show)
            try! realm.write {
                realm.add(favoritedSource)
            }
        }
    }
    
    public func unfavoriteSource(show: CompleteShowInformation) -> Bool {
        let realm = try! Realm()
        
        let favoritedSourceQuery = realm.object(ofType: FavoritedSource.self, forPrimaryKey: show.source.uuid.uuidString)

        if let favoritedSource = favoritedSourceQuery {
            try! realm.write {
                realm.delete(favoritedSource)
            }
            
            return true
        }
        
        return false
    }
    
    public func favoriteArtist(artist: ArtistWithCounts) {
        let realm = try! Realm()
        
        let favoritedArtist = FavoritedArtist(artist_uuid: artist.uuid.uuidString)
        try! realm.write {
            realm.add(favoritedArtist)
        }
    }
    
    public func removeArtist(artist: ArtistWithCounts) -> Bool {
        let realm = try! Realm()
        
        let favoritedArtistQuery = realm.object(ofType: FavoritedArtist.self, forPrimaryKey: artist.uuid.uuidString)
        
        if let favoritedArtist = favoritedArtistQuery {
            try! realm.write {
                realm.delete(favoritedArtist)
            }
            
            return true
        }
        
        return false
    }
}

// MARK: Favorite queries
public extension MyLibrary {
    public func isFavorite(artist: SlimArtist) -> Bool {
        return favorites.artists.filter("uuid == %@", artist.uuid.uuidString).count > 0
    }
    
    public func isFavorite(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return favorites.shows.filter("uuid == %@", show.uuid.uuidString).count > 0
    }
    
    public func isFavorite(source: SourceFull) -> Bool {
        return favorites.sources.filter("uuid == %@", source.uuid.uuidString).count > 0
    }

    public func isFavorite(track: SourceTrack) -> Bool {
        return favorites.tracks.filter("uuid == %@", track.uuid.uuidString).count > 0
    }
}

// MARK: Realm Object Helpers
extension RecentlyPlayedTrack {
    public convenience init(withUUID uuid: String? = nil, withTrack track: Track) {
        self.init(uuid: uuid, artist_uuid: track.showInfo.artist.uuid.uuidString, show_uuid: track.showInfo.show.uuid.uuidString, source_uuid: track.showInfo.source.uuid.uuidString, track_uuid: track.sourceTrack.uuid.uuidString)
    }
    
    public convenience init(withUUID uuid: String? = nil, withShowInfo showInfo: CompleteShowInformation, trackUUID: String) {
        self.init(uuid: uuid, artist_uuid: showInfo.artist.uuid.uuidString, show_uuid: showInfo.show.uuid.uuidString, source_uuid: showInfo.source.uuid.uuidString, track_uuid: trackUUID)
    }
}

extension FavoritedSource {
    public convenience init(withUUID uuid: String? = nil, withShowInfo showInfo: CompleteShowInformation) {
        self.init(source_uuid: showInfo.source.uuid.uuidString, artist_uuid: showInfo.artist.uuid.uuidString, show_uuid: showInfo.show.uuid.uuidString, show_date: showInfo.show.date)
    }
}

extension OfflineTrack {
    public convenience init(withTrack track: Track, state: OfflineTrackState? = nil, fileSize: Int? = nil) {
        self.init(track_uuid: track.sourceTrack.uuid.uuidString, artist_uuid: track.showInfo.artist.uuid.uuidString, show_uuid: track.showInfo.show.uuid.uuidString, source_uuid: track.showInfo.source.uuid.uuidString, state: state, file_size: fileSize)
    }
}

extension OfflineSource {
    public convenience init(withTrack track: Track) {
        self.init(source_uuid: track.showInfo.source.uuid.uuidString, artist_uuid: track.showInfo.artist.uuid.uuidString, show_uuid: track.showInfo.show.uuid.uuidString, year_uuid: track.showInfo.show.year.uuid.uuidString)
    }
}
