//
//  CarPlayDataSource.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/27/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import MediaPlayer
import Observable
import Siesta

protocol CarPlayDataSourceDelegate : class {
    func carPlayDataSourceWillUpdate();
    func carPlayDataSourceDidUpdate();
}

protocol Lockable {
    var locked : Bool { get set }
    var delegate : CarPlayDataSourceDelegate? { get set }
}

class LockableDataItem<T> : Lockable {
    private var _backingItem : T
    private var _updatedBackingItem : T?
    public var item : T {
        get { return _backingItem }
        set {
            queue.async {
                if self.locked {
                    self._updatedBackingItem = newValue
                } else {
                    self.delegate?.carPlayDataSourceWillUpdate()
                    self._backingItem = newValue
                    self.delegate?.carPlayDataSourceDidUpdate()
                }
            }
        }
    }
    
    private var _locked : Bool = false
    public var locked : Bool {
        get { return _locked }
        set {
            dispatchPrecondition(condition: .onQueue(queue))
            self._locked = newValue
            if !self._locked, let update = self._updatedBackingItem {
                self.delegate?.carPlayDataSourceWillUpdate()
                self._backingItem = update
                self.delegate?.carPlayDataSourceDidUpdate()
            }
        }
    }
    
    private var queue : DispatchQueue
    public weak var delegate : CarPlayDataSourceDelegate?
    public init(_ item : T, queue: DispatchQueue, delegate : CarPlayDataSourceDelegate?) {
        _backingItem = item
        self.queue = queue
        self.delegate = delegate
    }
}

class CarPlayDataSource {
    weak var delegate : CarPlayDataSourceDelegate? {
        didSet {
            for var item in lockableDataItems {
                item.delegate = delegate
            }
        }
    }

    private var disposal = Disposal()
    private let queue = DispatchQueue(label: "net.relisten.CarPlay.DataSource")
    
    public init(delegate: CarPlayDataSourceDelegate? = nil) {
        self.delegate = delegate
        
        _recentlyPlayedShows = LockableDataItem<[CompleteShowInformation]>([], queue: queue, delegate: delegate)
        _favoriteShowsByArtist = LockableDataItem<[Artist : [CompleteShowInformation]]>([:], queue: queue, delegate: delegate)
        _offlineShowsByArtist = LockableDataItem<[Artist : [OfflineSourceMetadata]]>([:], queue: queue, delegate: delegate)
        _sortedArtistsWithFavorites = LockableDataItem<[ArtistWithCounts]>([], queue: queue, delegate: delegate)
        lockableDataItems = [_recentlyPlayedShows, _favoriteShowsByArtist, _offlineShowsByArtist, _sortedArtistsWithFavorites]
        
        MyLibrary.shared.observeRecentlyPlayedTracks.observe({ [weak self] tracks, _ in
            guard let s = self else { return }
            s.queue.async {
                s.reloadRecentTracks(tracks: tracks)
            }
        }).add(to: &disposal)
        
        MyLibrary.shared.observeOfflineSources.observe({ [weak self] shows, _ in
            guard let s = self else { return }
            s.queue.async {
                s.reloadOfflineSources(shows: shows)
            }
        }).add(to: &disposal)
        
        MyLibrary.shared.observeFavoriteArtistIds.observe({ [weak self] artistIds, _ in
            guard let s = self else { return }
            s.queue.async {
                s.reloadFavoriteArtistIds(artistIds: Array(artistIds))
            }
        }).add(to: &disposal)
        
        MyLibrary.shared.observeMyShows.observe({ [weak self] shows, _ in
            guard let s = self else { return }
            s.queue.async {
                s.reloadFavorites(shows: MyLibrary.shared.shows)
            }
        }).add(to: &disposal)
        
        loadArtists()
    }
    
    deinit {
        RelistenApi.artists().removeObservers(ownedBy: self)
    }
    
    private func loadArtists() {
        let resource = RelistenApi.artists()
        resource.addObserver(owner: self) { [weak self] (resource, _) in
            guard let s = self else { return }
            if let artistsWithCounts : [ArtistWithCounts] = resource.latestData?.typedContent()  {
                s.queue.async {
                    s.reloadArtists(artistsWithCounts: artistsWithCounts)
                }
            }
        }
        resource.loadFromCacheThenUpdate()
    }
    
    // MARK: Recently Played
    public func recentlyPlayedShows() -> [CompleteShowInformation] {
        var retval : [CompleteShowInformation]? = nil
        queue.sync {
            retval = _recentlyPlayedShows.item
        }
        return retval!
    }
    
    // MARK: Downloads
    public func artistsWithOfflineShows() -> [Artist] {
        var retval : [Artist]? = nil
        queue.sync {
            retval = _offlineShowsByArtist.item.keys.sorted(by: { $0.name > $1.name })
        }
        return retval!
    }
    
    public func offlineShowsForArtist(_ artist: Artist) -> [OfflineSourceMetadata]? {
        var retval : [OfflineSourceMetadata]? = nil
        queue.sync {
            retval = _offlineShowsByArtist.item[artist]
        }
        return retval!
    }
    
    // MARK: Favorite Shows
    public func artistsWithFavoritedShows() -> [Artist] {
        var retval : [Artist]? = nil
        queue.sync {
            retval = _favoriteShowsByArtist.item.keys.sorted(by: { $0.name > $1.name })
        }
        return retval!
    }
    
    public func favoriteShowsForArtist(_ artist: Artist) -> [CompleteShowInformation]? {
        var retval : [CompleteShowInformation]? = nil
        queue.sync {
            retval = _favoriteShowsByArtist.item[artist]
        }
        return retval!
    }
    
    // MARK: All Artists
    public func allArtists() -> [ArtistWithCounts] {
        var retval : [ArtistWithCounts]? = nil
        queue.sync {
            retval = _sortedArtistsWithFavorites.item
        }
        return retval!
    }
    
    public func years(forArtist artist: ArtistWithCounts) -> [Year]? {
        var years : [Year]? = RelistenApi.years(byArtist: artist).latestData?.typedContent()
        if let y = years {
            years = sortedYears(from: y, for: artist)
        }
        return years
    }
    
    public func shows(forArtist artist : ArtistWithCounts, inYear year : Year) -> [Show]? {
        var shows : [Show]? = nil
        let yearWithShows : YearWithShows? = RelistenApi.shows(inYear: year, byArtist: artist).latestData?.typedContent()
        if let yearWithShows = yearWithShows {
            if artist.shouldSortYearsDescending {
                shows = yearWithShows.shows.sorted(by: { $0.date.timeIntervalSince($1.date) > 0 })
            } else {
                shows = yearWithShows.shows
            }
        }
        return shows
    }
    
    public func completeShow(forArtist artist : ArtistWithCounts, show : Show) -> CompleteShowInformation? {
        var completeShowInfo : CompleteShowInformation? = nil
        let showWithSources : ShowWithSources? = RelistenApi.showWithSources(forShow: show, byArtist: artist).latestData?.typedContent()
        if let showWithSources = showWithSources {
            let source : SourceFull? = showWithSources.sources.first
            if let source = source {
                completeShowInfo = CompleteShowInformation(source: source, show: show, artist: artist)
            }
        }
        return completeShowInfo
    }
    
    // MARK: Sorting Data
    private func sortArtistsWithFavorites(_ artists : [ArtistWithCounts]) -> [ArtistWithCounts] {
        var favoriteArtists : [ArtistWithCounts] = []
        var remainingArtists : [ArtistWithCounts] = []
        for artist : ArtistWithCounts in artists {
            if _favoriteArtistIds.contains(artist.id) {
                favoriteArtists.append(artist)
            } else {
                remainingArtists.append(artist)
            }
        }
        return favoriteArtists + remainingArtists
    }
    
    // MARK: Reloading Data
    public func lockData() {
        queue.async {
            for var item in self.lockableDataItems {
                item.locked = true
            }
        }
    }
    
    public func unlockData() {
        queue.async {
            for var item in self.lockableDataItems {
                item.locked = false
            }
        }
    }
    
    private var lockableDataItems : [Lockable]
    private var _recentlyPlayedShows: LockableDataItem<[CompleteShowInformation]>
    private var _offlineShowsByArtist: LockableDataItem<[Artist : [OfflineSourceMetadata]]>
    private var _favoriteShowsByArtist: LockableDataItem<[Artist : [CompleteShowInformation]]>
    
    private var _sortedArtistsWithFavorites : LockableDataItem<[ArtistWithCounts]>
    private var _favoriteArtistIds : [Int] = [] {
        didSet {
            _sortedArtistsWithFavorites.item = self.sortArtistsWithFavorites(_sortedArtistsWithFavorites.item)
        }
    }
    
    public func reloadArtists(artistsWithCounts: [ArtistWithCounts]) {
        dispatchPrecondition(condition: .onQueue(queue))
        let artists = self.sortArtistsWithFavorites(artistsWithCounts)
        if !(artists == _sortedArtistsWithFavorites.item) {
            _sortedArtistsWithFavorites.item = artists
        }
    }
    
    private func reloadRecentTracks(tracks: [Track]) {
        dispatchPrecondition(condition: .onQueue(queue))
        let recentShows : [CompleteShowInformation] = tracks.map { (track : Track) -> CompleteShowInformation in
            return track.showInfo
        }
        if !(recentShows == _recentlyPlayedShows.item) {
            _recentlyPlayedShows.item = recentShows
        }
    }
    
    private func reloadOfflineSources(shows: Set<OfflineSourceMetadata>) {
        dispatchPrecondition(condition: .onQueue(queue))
        var offlineShowsByArtist : [Artist : [OfflineSourceMetadata]] = [:]
        shows.forEach { (show) in
            var artistShows = offlineShowsByArtist[show.artist]
            if artistShows == nil {
                artistShows = []
            }
            artistShows?.append(show)
            offlineShowsByArtist[show.artist] = artistShows
        }
        if !(offlineShowsByArtist == _offlineShowsByArtist.item) {
            _offlineShowsByArtist.item = offlineShowsByArtist
        }
    }
    
    private func reloadFavoriteArtistIds(artistIds: [Int]) {
        dispatchPrecondition(condition: .onQueue(queue))
        _favoriteArtistIds = artistIds
    }
    
    private func reloadFavorites(shows: [CompleteShowInformation]) {
        dispatchPrecondition(condition: .onQueue(queue))
        var showsByArtist : [Artist : [CompleteShowInformation]] = [:]
        shows.forEach { (show) in
            var artistShows = showsByArtist[show.artist]
            if artistShows == nil {
                artistShows = []
            }
            artistShows?.append(show)
            showsByArtist[show.artist] = artistShows
        }
        if !(showsByArtist == _favoriteShowsByArtist.item) {
            _favoriteShowsByArtist.item = showsByArtist
        }
    }

}
