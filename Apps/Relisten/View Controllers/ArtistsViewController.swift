//
//  ArtistsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import RelistenShared

import Siesta
import AsyncDisplayKit
import RealmSwift

class ArtistsViewController: RelistenAsyncTableController<[ArtistWithCounts]>, ASCollectionDelegate {
    enum Sections: Int, RawRepresentable {
        case recentlyPlayed = 0
        case favoritedShows
        case availableOffline
        case recentlyPerformed
        case allRecentlyUpdated
        case favorited
        case featured
        case all
        case count
    }
    
    public var recentlyPlayedTracks: [Track] = []
    public var favoriteArtists: [UUID] = []
    public var offlineShows: [CompleteShowInformation] = []
    public var favoriteShows: [CompleteShowInformation] = []
    public var allRecentlyUpdatedShows: [ShowWithArtist] = []
    public var recentlyPerformedShows: [ShowWithArtist] = []

    public var allArtists: [ArtistWithCounts] = []
    public var featuredArtists: [ArtistWithCounts] = []
    
    public let recentShowsNode: HorizontalShowCollectionCellNode
    public let offlineShowsNode: HorizontalShowCollectionCellNode
    public let favoritedSourcesNode: HorizontalShowCollectionCellNode
    public let recentlyPerformedNode: HorizontalShowCollectionCellNode
    public let allRecentlyUpdatedNode: HorizontalShowCollectionCellNode
    
    public var resourceRecentlyPerformed: Resource? = nil
    public let resourceRecentlyUpdated: Resource

    public init() {
        recentShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        offlineShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        favoritedSourcesNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        recentlyPerformedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        allRecentlyUpdatedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)

        resourceRecentlyUpdated = RelistenApi.recentlyUpdated()

        super.init(useCache: true, refreshOnAppear: true)
        
        recentShowsNode.collectionNode.delegate = self
        offlineShowsNode.collectionNode.delegate = self
        favoritedSourcesNode.collectionNode.delegate = self
        recentlyPerformedNode.collectionNode.delegate = self
        allRecentlyUpdatedNode.collectionNode.delegate = self
        
        resourceRecentlyUpdated.addObserver(self)
        resourceRecentlyUpdated.loadFromCacheThenUpdate()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Relisten"
        
        let cb: Event<Any>.EventHandler = { [weak self] _ in self?.render() }
        
        DownloadManager.shared.eventTrackFinishedDownloading.addHandler(cb).add(to: &disposal)
        DownloadManager.shared.eventTracksDeleted.addHandler(cb).add(to: &disposal)

        let library = MyLibrary.shared
        
        library.favorites.artists.observeWithValue { [weak self] artists, changes in
            guard let s = self else { return }

            let previousFavoriteCount = s.favoriteArtists.count
            s.favoriteArtists = Array(artists.map({ UUID(uuidString: $0.artist_uuid)! }))

            let newFavoriteCount = s.favoriteArtists.count

            s.resourceRecentlyPerformed = RelistenApi.recentlyPerformed(byArtists: s.favoriteArtists)
            s.resourceRecentlyPerformed?.addObserver(s)
            s.resourceRecentlyPerformed?.loadFromCacheThenUpdate()
            
            switch changes {
            case .initial:
                s.tableNode.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                s.tableNode.performBatch(animated: true, updates: {
                    s.tableNode.insertRows(at: insertions.map({ IndexPath(row: $0, section: Sections.favorited.rawValue) }),
                                           with: .automatic)
                    s.tableNode.deleteRows(at: deletions.map({ IndexPath(row: $0, section: Sections.favorited.rawValue)}),
                                           with: .automatic)
                    s.tableNode.reloadRows(at: modifications.map({ IndexPath(row: $0, section: Sections.favorited.rawValue) }),
                                           with: .automatic)
                    
                    if previousFavoriteCount == 0, newFavoriteCount > 0 {
                        s.tableNode.reloadSections(IndexSet(integer: Sections.favorited.rawValue), with: .automatic)
                    }
                }, completion: nil)
            case .error(let error):
                fatalError(error.localizedDescription)
            }
        }.dispose(to: &disposal)
        
//        favoriteArtists = Array(library.favorites.artists.map({ UUID(uuidString: $0.artist_uuid)! }))

        library.recent.shows.observeWithValue { [weak self] recentlyPlayed, changes in
            guard let s = self else { return }
            
            s.reloadRecentShows(tracks: recentlyPlayed.asTracks())
        }.dispose(to: &disposal)

        library.offline.sources.observeWithValue { [weak self] offlineSources, changes in
            guard let s = self else { return }
            
            s.reloadOfflineSources(shows: offlineSources.asCompleteShows())
        }.dispose(to: &disposal)
        
        library.favorites.sources.observeWithValue{ [weak self] favoriteSources, changes in
            guard let s = self else { return }
            
            s.reloadFavoriteSources(shows: favoriteSources.asCompleteShows())
        }.dispose(to: &disposal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppColors_SwitchToRelisten(navigationController)
    }
    
    override func has(oldData old: [ArtistWithCounts], changed new: [ArtistWithCounts]) -> Bool {
        return old.count != new.count
    }
    
    override func dataChanged(_ data: [ArtistWithCounts]) {
        allArtists = data
        featuredArtists = data.filter({ $0.featured > 0 })
    }

    override var resource: Resource? { get { return api.artists() } }
    
    private func reloadOfflineSources(shows: [CompleteShowInformation]) {
        if !(shows == offlineShows) {
            DispatchQueue.main.async {
                self.offlineShows = shows
                self.offlineShowsNode.shows = self.offlineShows.map({ ($0.show, $0.artist) })
                self.tableNode.reloadSections([ Sections.availableOffline.rawValue ], with: .automatic)
            }
        }
    }
    
    private func reloadFavoriteSources(shows: [CompleteShowInformation]) {
        if !(shows == favoriteShows) {
            DispatchQueue.main.async {
                self.favoriteShows = shows
                self.favoritedSourcesNode.shows = self.favoriteShows.map({ ($0.show, $0.artist) })
                self.tableNode.reloadSections([ Sections.favoritedShows.rawValue ], with: .automatic)
            }
        }
    }

    private func reloadRecentShows(tracks: [Track]) {
        DispatchQueue.main.async {
            self.recentlyPlayedTracks = tracks
            
            let recentShows = self.recentlyPlayedTracks.map({ ($0.showInfo.show, $0.showInfo.artist) }) as [(show: Show, artist: Artist?)]
            
            self.recentShowsNode.shows = recentShows
            self.tableNode.reloadSections([ Sections.recentlyPlayed.rawValue ], with: .automatic)
        }
    }
    
    // MARK: Resource
    override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        if resource == resourceRecentlyPerformed || resource == resourceRecentlyUpdated {
            switch event {
            case .newData(_):
                break
            default:
                return
            }
            
            DispatchQueue.main.async {
                if resource == self.resourceRecentlyPerformed {
                    self.recentlyPerformedShows = resource.typedContent(ifNone: [])
                    self.recentlyPerformedNode.shows = self.recentlyPerformedShows.map { (show: $0, artist: $0.artist) }
                    self.tableNode.reloadSections([ Sections.recentlyPerformed.rawValue ], with: .automatic)
                }
                else if resource == self.resourceRecentlyUpdated {
                    self.allRecentlyUpdatedShows = resource.typedContent(ifNone: [])
                    self.allRecentlyUpdatedNode.shows = self.allRecentlyUpdatedShows.map { (show: $0, artist: $0.artist) }
                    self.tableNode.reloadSections([ Sections.allRecentlyUpdated.rawValue ], with: .automatic)
                }
            }
        }
        else {
            return super.resourceChanged(resource, event: event)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .recentlyPlayed:
            return recentlyPlayedTracks.count > 0 ? 1 : 0
        case .availableOffline:
            return offlineShows.count > 0 ? 1 : 0
        case .favorited:
            return allArtists.count == 0 ? 0 : favoriteArtists.count
        case .featured:
            return featuredArtists.count
        case .all:
            return allArtists.count
        case .favoritedShows:
            return favoriteShows.count > 0 ? 1 : 0
        case .recentlyPerformed:
            return recentlyPerformedShows.count > 0 ? 1 : 0
        case .allRecentlyUpdated:
            return allRecentlyUpdatedShows.count > 0 ? 1 : 0
        case .count:
            fatalError()
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let row = indexPath.row
        
        switch Sections(rawValue: indexPath.section)! {
        case .recentlyPlayed:
            let n = recentShowsNode
            return { n }
        case .availableOffline:
            let n = offlineShowsNode
            return { n }
        case .favoritedShows:
            let n = favoritedSourcesNode
            return { n }
        case .recentlyPerformed:
            let n = recentlyPerformedNode
            return { n }
        case .allRecentlyUpdated:
            let n = allRecentlyUpdatedNode
            return { n }
        
        case .favorited:
            let artist = allArtists.first(where: { art in art.uuid == favoriteArtists[row] })!
            
            return { ArtistCellNode(artist: artist, withFavoritedArtists: self.favoriteArtists) }
        case .featured:
            let artist = featuredArtists[row]
            
            return { ArtistCellNode(artist: artist, withFavoritedArtists: self.favoriteArtists) }
        case .all:
            let artist = allArtists[indexPath.row]
            
            return { ArtistCellNode(artist: artist, withFavoritedArtists: self.favoriteArtists) }
        case .count:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        
        switch Sections(rawValue: indexPath.section)! {
        case .favorited:
            let artist = allArtists.first(where: { art in art.uuid == favoriteArtists[row] })!
            
            navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
        case .featured:
            let artist = featuredArtists[row]
            
            navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
        case .all:
            let artist = allArtists[indexPath.row]
            
            navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .recentlyPlayed:
            return recentlyPlayedTracks.count > 0 ? "Recently Played" : nil
        case .availableOffline:
            return offlineShows.count > 0 ? "Available Offline" : nil
        case .favorited:
            return favoriteArtists.count > 0 ? "Favorite" : nil
        case .featured:
            return "Featured"
        case .all:
            if let artists = latestData {
                return "All \(artists.count) Artists"
            }
            
            return "All Artists"
        case .favoritedShows:
            return favoriteShows.count > 0 ? "My Favorites" : nil
        case .recentlyPerformed:
            return recentlyPerformedShows.count > 0 ? "Recently by Favorites" : nil
        case .allRecentlyUpdated:
            return allRecentlyUpdatedShows.count > 0 ? "Latest Recordings" : nil
        
        case .count:
            fatalError()
        }
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let show: Show?
        let artist: Artist?
        var source: SourceFull? = nil
        
        if collectionNode === recentShowsNode.collectionNode {
            let s = recentlyPlayedTracks[indexPath.item]
            show = s.showInfo.show
            artist = s.showInfo.artist
            source = s.showInfo.source
        }
        else if collectionNode === offlineShowsNode.collectionNode {
            let s = offlineShows[indexPath.item]
            show = s.show
            artist = s.artist
            source = s.source
        }
        else if collectionNode === favoritedSourcesNode.collectionNode {
            let s = favoriteShows[indexPath.item]
            show = s.show
            artist = s.artist
            source = s.source
        }
        else if collectionNode === recentlyPerformedNode.collectionNode {
            let s = recentlyPerformedShows[indexPath.item]
            show = s
            artist = s.artist
        }
        else if collectionNode === allRecentlyUpdatedNode.collectionNode {
            let s = allRecentlyUpdatedShows[indexPath.item]
            show = s
            artist = s.artist
        }
        else {
            show = nil
            artist = nil
        }
        
        if let s = show, let a = artist {
            let sourcesController = SourcesViewController(artist: a, show: s)
            
            if let src = source {
                sourcesController.presentIfNecessary(navigationController: navigationController, forSource: src)
            }
            else {
                sourcesController.presentIfNecessary(navigationController: navigationController)
            }
        }
    }
}
