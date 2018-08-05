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
import EasyRealm

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
    
    public var recentlyPlayed: Results<RecentlyPlayedTrack> {
        get {
            let realm = try! Realm()
            return realm
                .objects(RecentlyPlayedTrack.self)
                .sorted(byKeyPath: "updated_at", ascending: false)
        }
    }
    
    public let offline = MyLibraryOffline()
    public let favorites = MyLibraryFavorites()
    
    public var downloadBacklog: [Track] = []
    
    internal let realmQueue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.library.realm")
    internal let diskUseQueue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.library.diskUse")
    
    private init() {
    }
}

// MARK: Recently Played
extension MyLibrary {
    public func recentlyPlayedByArtist(_ artist: SlimArtist) -> Results<RecentlyPlayedTrack> {
        let realm = try! Realm()
        return realm
            .objects(RecentlyPlayedTrack.self)
            .filter("artist_uuid == %@", artist.uuid)
            .sorted(byKeyPath: "updated_at", ascending: false)
    }
    
    public func trackWasPlayed(_ track: Track) -> Bool {
        let realm = try! Realm()
        
        let recentShow = RecentlyPlayedTrack()
        recentShow.show_uuid = track.showInfo.show.uuid
        recentShow.source_uuid = track.showInfo.source.uuid
        recentShow.artist_uuid = track.showInfo.artist.uuid
        recentShow.track_uuid = track.sourceTrack.uuid
        
        recentShow.created_at = Date()
        recentShow.updated_at = Date()
        
        try! realm.write {
            realm.add(recentShow)
        }
        
        return true
    }
}

// MARK: Offline Tracks
extension MyLibrary {
    public func offlinePlayedByArtist(_ artist: SlimArtist) -> Results<OfflineSource> {
        return offline.sources
            .filter("artist_uuid == %@", artist.uuid)
            .sorted(byKeyPath: "created_at", ascending: false)
    }
    
    public func isTrackAvailableOffline(_ track: Track) -> Bool {
        return isTrackAvailableOffline(track.sourceTrack)
    }
    
    public func isTrackAvailableOffline(_ track: SourceTrack) -> Bool {
        return offline.tracks.filter("uuid == %@ AND state >= %d", track.uuid, OfflineTrackState.downloaded).count > 0
    }
    
    public func isSourceFullyAvailableOffline(_ source: SourceFull) -> Bool {
        if sinq(source.tracksFlattened).any({ !isTrackAvailableOffline($0) }) {
            return false
        }
        
        return true
    }
    
    public func isArtistAtLeastPartiallyAvailableOffline(_ artist: SlimArtist) -> Bool {
        return offline.tracks.filter("artist_uuid == %@ AND state >= %d", artist.uuid, OfflineTrackState.downloaded).count > 0
    }
    
    public func isShowAtLeastPartiallyAvailableOffline(_ show: Show) -> Bool {
        return offline.tracks.filter("show_uuid == %@ AND state >= %d", show.uuid, OfflineTrackState.downloaded).count > 0
    }
    
    public func isSourceAtLeastPartiallyAvailableOffline(_ source: SourceFull) -> Bool {
        return offline.tracks.filter("source_uuid == %@ AND state >= %d", source.uuid, OfflineTrackState.downloaded).count > 0
    }
    
    public func isYearAtLeastPartiallyAvailableOffline(_ year: Year) -> Bool {
        return offline.sources.filter("year_uuid == %@", year.uuid).count > 0
    }
}


extension MyLibrary : RelistenDownloadManagerDataSource {
    public func nextTrackToDownload() -> Track? {
        let realm = try! Realm()
        
        return realm.objects(OfflineTrack.self)
            .filter("state == %d", OfflineTrackState.downloadQueued)
            .sorted(byKeyPath: "created_at", ascending: true)
            .first?
            .track
    }

    public func offlineTrackQueuedToBacklog(_ track: Track) {
        let realm = try! Realm()
        
        let trackMeta = OfflineTrack()
        trackMeta.track_uuid = track.sourceTrack.uuid
        trackMeta.show_uuid = track.showInfo.show.uuid
        trackMeta.source_uuid = track.showInfo.source.uuid
        trackMeta.artist_uuid = track.showInfo.artist.uuid
        trackMeta.state = .downloadQueued
        trackMeta.created_at = Date()
        
        try! realm.write {
            realm.add(trackMeta)
        }
    }
    
    public func offlineTrackBeganDownloading(_ track: Track) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .downloading
            }
        }
        else {
            assertionFailure("!!! ERROR: track began downloading BEFORE BEING STORED IN REALM !!!")
        }
    }
    
    public func offlineTrackFinishedDownloading(_ track: Track, withSize fileSize: UInt64) {
        let realm = try! Realm()
        
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .downloaded
                offlineTrack.file_size.value = Int(fileSize)
            }
        }
        else {
            assertionFailure("!!! ERROR: track finished downloading BEFORE BEING STORED IN REALM !!!")
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
    
    public func offlineTrackWillBeDeleted(_ track: Track) {
        let realm = try! Realm()
        let offlineTrackQuery = realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid)
        
        if let offlineTrack = offlineTrackQuery {
            try! realm.write {
                offlineTrack.state = .deleting
            }
        }
        else {
            assertionFailure("!!! ERROR: OFFLINE TRACK SIZE BECAME KNOWN BEFORE BEING STORED IN REALM !!!")
        }
    }
    
    public func offlineTrackWasDeleted(_ track: Track) {
        let realm = try! Realm()
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
    
}

// MARK: Favorites
extension MyLibrary {
    public func favoritedSourcesPlayedByArtist(_ artist: SlimArtist) -> Results<FavoritedSource> {
        return favorites.sources
            .filter("artist_uuid == %@", artist.uuid)
            .sorted(byKeyPath: "show_date", ascending: false)
    }
    
    public func favoriteSource(show: CompleteShowInformation) {
        let realm = try! Realm()
        
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
        let realm = try! Realm()
        
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
        let realm = try! Realm()
        
        let favoritedArtist = FavoritedArtist()
        favoritedArtist.uuid = artist.uuid
        favoritedArtist.created_at = Date()
        
        try! realm.write {
            realm.add(favoritedArtist)
        }
    }
    
    public func removeArtist(artist: ArtistWithCounts) -> Bool {
        let realm = try! Realm()
        
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

// MARK: Favorite queries
public extension MyLibrary {
    public func isFavorite(artist: SlimArtist) -> Bool {
        return favorites.artists.filter("uuid == %@", artist.uuid).count > 0
    }
    
    public func isFavorite(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return favorites.shows.filter("uuid == %@", show.uuid).count > 0
    }
    
    public func isFavorite(source: SourceFull) -> Bool {
        return favorites.sources.filter("uuid == %@", source.uuid).count > 0
    }

    public func isFavorite(track: SourceTrack) -> Bool {
        return favorites.tracks.filter("uuid == %@", track.uuid).count > 0
    }
}
