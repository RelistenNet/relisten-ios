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

public class MyLibraryFavorites {
    public let artists: Results<FavoritedArtist>
    public let shows: Results<FavoritedShow>
    public let sources: Results<FavoritedSource>
    public let tracks: Results<FavoritedTrack>

    public init() {
        let realm = try! Realm()
        
        artists = realm.objects(FavoritedArtist.self)
        shows = realm.objects(FavoritedShow.self)
        sources = realm.objects(FavoritedSource.self)
        tracks = realm.objects(FavoritedTrack.self)
    }
}

public typealias FullOfflineSource = (show: ShowWithSources, source: SourceFull, date_added: Date)

public class MyLibraryOffline {
    public let sources: Results<OfflineSource>
    public let tracks: Results<OfflineTrack>
    
    public init() {
        let realm = try! Realm()
        
        sources = realm.objects(OfflineSource.self)
        tracks = realm.objects(OfflineTrack.self)
    }
}

public class MyLibrary {
    public static let shared = MyLibrary()
    
    internal let realm: Realm
    public let recentlyPlayed: Results<RecentlyPlayedShow>
    
    public let offline = MyLibraryOffline()
    public let favorites = MyLibraryFavorites()
    
    public var downloadBacklog: [Track] = []
    
    private static let offlineCacheName = "offline"
    
    public let offlineCache : Storage<Set<URL>>
    public let offlineCacheDownloadBacklogStorage : Storage<[Track]>
    public let offlineCacheSourcesMetadata : Storage<Set<OfflineSourceMetadata>>

    internal let diskUseQueue : DispatchQueue = DispatchQueue(label: "live.relisten.library.diskUse")
    internal let diskUseQueueKey = DispatchSpecificKey<Int>()
    
    private init() {
        realm = try! Realm()
        
        recentlyPlayed = realm
            .objects(RecentlyPlayedShow.self)
            .sorted(byKeyPath: "updated_at", ascending: false)
        
        offlineCache = try! Storage(
            diskConfig: DiskConfig(
                name: MyLibrary.offlineCacheName,
                expiry: .never,
                maxSize: 1024 * 1024 * 250,
                directory: PersistentCacheDirectory
            ),
            memoryConfig: MemoryConfig(
                expiry: .never,
                countLimit: 4000,
                totalCostLimit: 1024 * 1024 * 2
            ),
            transformer: TransformerFactory.forCodable(ofType: Set<URL>.self)
        )
        
        offlineCacheDownloadBacklogStorage = offlineCache.transformCodable(ofType: [Track].self)
        
        diskUseQueue.setSpecific(key: diskUseQueueKey, value: 1)
        
        try! loadOfflineData()
    }
    
    public func URLNotAvailableOffline(_ track: Track, save: Bool = true) {
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.sourceTrack.uuid)
        
        guard let offlineTrack = offlineTrackQuery else {
            return
        }
        
        try! realm.write {
            realm.delete(offlineTrack)
        }
        
        if !isSourceAtLeastPartiallyAvailableOffline(track.showInfo.source) {
            let offlineSourceQuery = realm.object(ofType: OfflineSource.self, forPrimaryKey: track.showInfo.source.uuid)
            
            if let offlineSource = offlineSourceQuery {
                try! realm.write {
                    realm.delete(offlineSource)
                }
            }
        }
    }
    
    public func isShowInLibrary(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return favorites.shows.contains(where: { $0.show_uuid == show.uuid })
    }
    
    public func queueToBacklog(_ track: Track) {
        downloadBacklog.append(track)
        
        saveDownloadBacklog()
    }
    
    public func dequeueFromBacklog() -> Track? {
        if downloadBacklog.count == 0 {
            return nil
        }
        
        let first = downloadBacklog.removeFirst()
        
        saveDownloadBacklog()
        
        return first
    }
}

extension MyLibrary : RelistenDownloadManagerDelegate {
    public func trackBecameAvailableOffline(_ track: Track) {
        let trackMeta = OfflineTrack()
        trackMeta.track_uuid = track.sourceTrack.uuid
        trackMeta.show_uuid = track.showInfo.show.uuid
        trackMeta.source_uuid = track.showInfo.source.uuid
        trackMeta.artist_uuid = track.showInfo.artist.uuid
        trackMeta.created_at = Date()

        try! realm.write {
            realm.add(trackMeta)
        }

        // add the source information if it doesn't exist
        let offlineSourceQuery = realm.object(ofType: OfflineSource.self, forPrimaryKey: track.showInfo.source.uuid)
        
        if offlineSourceQuery == nil {
            try! realm.write {
                let sourceMeta = OfflineSource()
                sourceMeta.show_uuid = track.showInfo.show.uuid
                sourceMeta.source_uuid = track.showInfo.source.uuid
                sourceMeta.artist_uuid = track.showInfo.artist.uuid
                sourceMeta.year_uuid = track.showInfo.show.year.uuid
                sourceMeta.created_at = Date()

                realm.add(sourceMeta)
            }
        }
    }
    
    public func trackSizeBecameKnown(_ track: SourceTrack, fileSize: UInt64) {
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.file_size.value = Int(fileSize)
            }
        }
        else {
            assertionFailure("!!! ERROR: OFFLINE TRACK SIZE BECAME KNOWN BEFORE BEING STORED IN REALM !!!")
        }
    }
}

/// boring loading and saving
extension MyLibrary {
    public func loadOfflineData() throws {
        do {
            downloadBacklog = try offlineCacheDownloadBacklogStorage.object(forKey: "downloadBacklog")
        }
        catch CocoaError.fileReadNoSuchFile {
            downloadBacklog = []
        }
    }
    
    public func saveOfflineData() {
        saveDownloadBacklog()
    }
    
    public func saveDownloadBacklog() {
        offlineCacheDownloadBacklogStorage.async.setObject(downloadBacklog, forKey: "downloadBacklog", completion: { _ in })
    }
}

/// offline checks
extension MyLibrary {
    public func isTrackAvailableOffline(_ track: Track) -> Bool {
        return isTrackAvailableOffline(track.sourceTrack)
    }
    
    public func isTrackAvailableOffline(_ track: SourceTrack) -> Bool {
        return offline.tracks.contains(where: { $0.track_uuid == track.uuid })
    }
    
    public func isSourceFullyAvailableOffline(_ source: SourceFull) -> Bool {
        if sinq(source.tracksFlattened).any({ !isTrackAvailableOffline($0) }) {
            return false
        }
        
        return true
    }
    
    public func isArtistAtLeastPartiallyAvailableOffline(_ artist: SlimArtist) -> Bool {
        return offline.sources.filter("artist_uuid = %@", artist.uuid).count > 0
    }
    
    public func isShowAtLeastPartiallyAvailableOffline(_ show: Show) -> Bool {
        return offline.sources.filter("show_uuid = %@", show.uuid).count > 0
    }
    
    public func isSourceAtLeastPartiallyAvailableOffline(_ source: SourceFull) -> Bool {
        return offline.sources.filter("source_uuid = %@", source.uuid).count > 0
    }
    
    public func isYearAtLeastPartiallyAvailableOffline(_ year: Year) -> Bool {
        return offline.sources.filter("year_uuid = %@", year.uuid).count > 0
    }
}

extension MyLibrary {
    public func recentlyPlayedByArtist(_ artist: SlimArtist) -> Results<RecentlyPlayedShow> {
        return recentlyPlayed
            .filter("artist_uuid = %@", artist.uuid)
            .sorted(byKeyPath: "updated_at", ascending: false)
    }
    
    public func offlinePlayedByArtist(_ artist: SlimArtist) -> Results<OfflineSource> {
        return offline.sources
            .filter("artist_uuid = %@", artist.uuid)
            .sorted(byKeyPath: "created_at", ascending: false)
    }
    
    public func favoritedShowsPlayedByArtist(_ artist: SlimArtist) -> Results<FavoritedSource> {
        return favorites.shows
            .filter("artist_uuid = %@", artist.uuid)
            .sorted(byKeyPath: "show_date", ascending: false)
    }
}

extension MyLibrary {
    public func trackWasPlayed(_ track: Track) -> Bool {
        let recentShowQuery = realm.object(ofType: RecentlyPlayedShow.self, forPrimaryKey: track.showInfo.show.uuid)
        
        if let recentShow = recentShowQuery {
            // set updated_at
            try! realm.write {
                recentShow.updated_at = Date()
            }
        }
        else {
            // insert
            let recentShow = RecentlyPlayedShow()
            recentShow.show_uuid = track.showInfo.show.uuid
            recentShow.source_uuid = track.showInfo.source.uuid
            recentShow.artist_uuid = track.showInfo.artist.uuid
            
            recentShow.created_at = Date()
            recentShow.updated_at = Date()
            
            try! realm.write {
                realm.add(recentShow)
            }
        }
        
        return true
    }
}

extension MyLibrary {
    public func favoriteSource(show: CompleteShowInformation) {
        let favoritedSource = FavoritedSource()
        favoritedSource.artist_uuid = show.artist.uuid
        favoritedSource.show_date = show.show.date
        favoritedSource.uuid = show.source.uuid
        favoritedSource.show_uuid = show.show.uuid
        
        favoritedSource.created_at = Date()
        
        try! realm.write {
            realm.add(favoritedSource)
        }
    }
    
    public func unfavoriteSource(show: CompleteShowInformation) -> Bool {
        let favoritedSourceQuery = realm.object(ofType: FavoritedSource.self, forPrimaryKey: show.show.uuid)

        if let favoritedSource = favoritedSourceQuery {
            try! realm.write {
                realm.delete(favoritedSource)
            }
            
            return true
        }
        
        return false
    }
    
    public func favoriteArtist(artist: ArtistWithCounts) {
        let favoritedArtist = FavoritedArtist()
        favoritedArtist.uuid = artist.uuid
        favoritedArtist.created_at = Date()
        
        try! realm.write {
            realm.add(favoritedArtist)
        }
    }
    
    public func removeArtist(artist: ArtistWithCounts) -> Bool {
        let favoritedArtistQuery = realm.object(ofType: FavoritedArtist.self, forPrimaryKey: artist.uuid)
        
        if let favoritedArtist = favoritedArtistQuery {
            try! realm.write {
                realm.delete(favoritedArtist)
            }
            
            return true
        }
        
        return false
    }
}
