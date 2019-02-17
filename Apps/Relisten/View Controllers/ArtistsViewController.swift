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
import SVProgressHUD

class ArtistsViewController: RelistenTableViewController<[ArtistWithCounts]>, ASCollectionDelegate, UISearchResultsUpdating {
    enum Sections: Int, RawRepresentable {
        case favorited = 0
        case recentlyPlayed
        case favoritedShows
        case availableOffline
        case featured
        case recentlyPerformed
        case allRecentlyUpdated
        case all
        case count
    }
    
    public var recentlyPlayedTracks: Results<RecentlyPlayedTrack>?
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
    
    public var filteredArtists: [ArtistWithCounts] = []
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    private let tableUpdateQueue = DispatchQueue(label: "net.relisten.groupedViewController.queue")
    
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
        
        let settingsItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(presentSettings(_:)))
        settingsItem.accessibilityLabel = "Settings"
        self.navigationItem.rightBarButtonItem = settingsItem
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Search Artists"
        searchController.searchBar.barStyle = .blackTranslucent
        searchController.searchBar.backgroundColor = AppColors.primary
        searchController.searchBar.barTintColor = AppColors.textOnPrimary
        searchController.searchBar.tintColor = AppColors.textOnPrimary
        
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    /*
    var hasReloaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasReloaded {
            tableNode.reloadData()
            
            hasReloaded = true
        }
    }
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Relisten"
        
        let cb: Event<Any>.EventHandler = { [weak self] _ in self?.render() }
        
        DownloadManager.shared.eventTrackFinishedDownloading.addHandler(cb).add(to: &disposal)
        DownloadManager.shared.eventTracksDeleted.addHandler(cb).add(to: &disposal)

        let library = MyLibrary.shared
        
        library.favorites.artists.observeWithValue { [weak self] artists, changes in
            guard let s = self else { return }

            s.reloadFavoriteArtists(artists: artists, changes: changes)
        }.dispose(to: &disposal)
        
        library.recent.shows.observeWithValue { [weak self] recentlyPlayed, changes in
            guard let s = self else { return }
            
            s.reloadRecentShows(tracks: recentlyPlayed)
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
    
    @objc func presentSettings(_ sender: UINavigationBar?) {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }
    
    override func has(oldData old: [ArtistWithCounts], changed new: [ArtistWithCounts]) -> Bool {
        return old.count != new.count
    }
    
    override func dataChanged(_ data: [ArtistWithCounts]) {
        DispatchQueue.main.async {
            self.allArtists = data
            self.featuredArtists = data.filter({ $0.featured > 0 })
        }
    }

    override var resource: Resource? { get { return api.artists() } }
    
    private func reloadOfflineSources(shows: [CompleteShowInformation]) {
        if !(shows == offlineShows) {
            DispatchQueue.main.async {
                self.offlineShows = shows
                self.offlineShowsNode.shows = self.offlineShows.map({ ($0.show, $0.artist, $0.source) })
                if self.isFiltering() == false {
                    self.tableNode.reloadSections([ Sections.availableOffline.rawValue ], with: .automatic)
                }
            }
        }
    }
    
    private func reloadFavoriteSources(shows: [CompleteShowInformation]) {
        if !(shows == favoriteShows) {
            DispatchQueue.main.async {
                self.favoriteShows = shows
                self.favoritedSourcesNode.shows = self.favoriteShows.map({ ($0.show, $0.artist, $0.source) })
                if self.isFiltering() == false {
                    self.tableNode.reloadSections([ Sections.favoritedShows.rawValue ], with: .automatic)
                }
            }
        }
    }

    private func reloadRecentShows(tracks: Results<RecentlyPlayedTrack>) {
        DispatchQueue.main.async {
            self.recentlyPlayedTracks = tracks
            
            if let recentShows = self.recentlyPlayedTracks?.asTracks().map({ ($0.showInfo.show, $0.showInfo.artist, $0.showInfo.source) }) as [(show: Show, artist: Artist?, source: Source?)]? {
                self.recentShowsNode.shows = recentShows
                if self.isFiltering() == false {
                    self.tableNode.reloadSections([ Sections.recentlyPlayed.rawValue ], with: .automatic)
                }
            }
        }
    }
    
    private func reloadFavoriteArtists(artists: Results<FavoritedArtist>, changes: RealmCollectionChange<Results<FavoritedArtist>>) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            
            let previousFavoriteCount = s.favoriteArtists.count
            let localFavoriteArtists = Array(artists.compactMap({ UUID(uuidString: $0.artist_uuid) }))
            
            let newFavoriteCount = localFavoriteArtists.count
            
            if s.isFiltering() == false {
                switch changes {
                case .initial:
                    s.tableNode.performBatch(animated: true, updates: {
                        s.favoriteArtists = localFavoriteArtists
                        s.tableNode.reloadSections(IndexSet(integer: Sections.favorited.rawValue), with: .automatic)
                    }, completion: nil)
                case .update(_, let deletions, let insertions, let modifications):
                    s.tableNode.performBatch(animated: true, updates: {
                        s.tableNode.insertRows(at: insertions.map({ IndexPath(row: $0, section: Sections.favorited.rawValue) }),
                                               with: .automatic)
                        s.tableNode.deleteRows(at: deletions.map({ IndexPath(row: $0, section: Sections.favorited.rawValue)}),
                                               with: .automatic)
                        s.tableNode.reloadRows(at: modifications.map({ IndexPath(row: $0, section: Sections.favorited.rawValue) }),
                                               with: .automatic)
                        
                        s.favoriteArtists = localFavoriteArtists
                        
                        if newFavoriteCount == 0 {
                            s.tableNode.deleteRows(at: (0..<s.recentlyPerformedShows.count).map( { IndexPath(row: $0, section: Sections.recentlyPerformed.rawValue) }), with: .automatic)
                            s.tableNode.reloadSections(IndexSet(integer: Sections.recentlyPerformed.rawValue), with: .automatic)
                            
                            s.resourceRecentlyPerformed = nil
                            s.recentlyPerformedShows = []
                            s.recentlyPerformedNode.shows = []
                        }
                        else {
                            s.resourceRecentlyPerformed = RelistenApi.recentlyPerformed(byArtists: s.favoriteArtists)
                            s.resourceRecentlyPerformed?.addObserver(s)
                            s.resourceRecentlyPerformed?.loadFromCacheThenUpdate()
                        }
                        
                        if previousFavoriteCount == 0, newFavoriteCount > 0 {
                            s.tableNode.reloadSections(IndexSet(integer: Sections.favorited.rawValue), with: .automatic)
                        }
                    }, completion: nil)
                case .error(let error):
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: Search
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return (searchController.isActive && !searchBarIsEmpty()) || searchBarScopeIsFiltering
    }
    
    func filterContentForSearchText(_ searchText: String) {
        let searchTextLC = searchText.lowercased()
        tableUpdateQueue.async {
            self.filteredArtists = self.allArtists.filter({ $0.name.lowercased().contains(searchTextLC) })
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        }
    }
    
    //MARK: UISearchResultsUpdating
    public func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
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
                    self.recentlyPerformedNode.shows = self.recentlyPerformedShows.map { (show: $0, artist: $0.artist, nil) }
                    if self.isFiltering() == false {
                        self.tableNode.reloadSections([ Sections.recentlyPerformed.rawValue ], with: .automatic)
                    }
                }
                else if resource == self.resourceRecentlyUpdated {
                    self.allRecentlyUpdatedShows = resource.typedContent(ifNone: [])
                    self.allRecentlyUpdatedNode.shows = self.allRecentlyUpdatedShows.map { (show: $0, artist: $0.artist, nil) }
                    if self.isFiltering() == false {
                        self.tableNode.reloadSections([ Sections.allRecentlyUpdated.rawValue ], with: .automatic)
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async {
                super.resourceChanged(resource, event: event)
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        if isFiltering() {
            return 1
        } else {
            return Sections.count.rawValue
        }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            var count : Int = 0
            tableUpdateQueue.sync {
                count = filteredArtists.count
            }
            return count
        } else {
            switch Sections(rawValue: section)! {
            case .recentlyPlayed:
                if let recentlyPlayedTracks = recentlyPlayedTracks {
                    return recentlyPlayedTracks.count > 0 ? 1 : 0
                } else {
                    return 0
                }
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
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        if isFiltering() {
            var artist : ArtistWithCounts? = nil
            tableUpdateQueue.sync {
                artist = filteredArtists[indexPath.row]
            }
            
            if let artist = artist {
                return { ArtistCellNode(artist: artist, withFavoritedArtists: self.favoriteArtists) }
            } else {
                fatalError("Couldn't get an artist at \(indexPath)")
            }
        } else {
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
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if isFiltering() {
            var artist : ArtistWithCounts? = nil
            tableUpdateQueue.sync {
                artist = filteredArtists[indexPath.row]
            }
            if let artist = artist {
                navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
            } else {
                fatalError("Couldn't get an artist at \(indexPath)")
            }
        } else {
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
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering() {
            return nil
        }
        
        switch Sections(rawValue: section)! {
        case .recentlyPlayed:
            if let recentlyPlayedTracks = recentlyPlayedTracks {
                return recentlyPlayedTracks.count > 0 ? "Recently Played" : nil
            } else {
                return nil
            }
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

    override public func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        var horizontalCollectionNode : HorizontalShowCollectionCellNode? = nil
        
        switch collectionNode {
        case recentShowsNode.collectionNode:
            horizontalCollectionNode = recentShowsNode
        case offlineShowsNode.collectionNode:
            horizontalCollectionNode = offlineShowsNode
        case favoritedSourcesNode.collectionNode:
            horizontalCollectionNode = favoritedSourcesNode
        case recentlyPerformedNode.collectionNode:
            horizontalCollectionNode = recentlyPerformedNode
        case allRecentlyUpdatedNode.collectionNode:
            horizontalCollectionNode = allRecentlyUpdatedNode
        default:
            break
        }
        
        if let horizontalCollectionNode = horizontalCollectionNode {
            horizontalCollectionNode.presentSourcesViewController(forIndexPath: indexPath, navigationController: navigationController)
        }
    }
}
