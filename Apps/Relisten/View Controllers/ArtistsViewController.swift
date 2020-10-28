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

class ArtistsViewController: RelistenTableViewController<[ArtistWithCounts]>, ASCollectionDelegate {
    enum Sections: Int, RawRepresentable {
        case favorited = 0
        case featured
        case recentlyPerformed
        case allRecentlyUpdated
        case all
        case count
    }
    
    public var favoriteArtists: [UUID] = []
    public var allRecentlyUpdatedShows: [ShowWithArtist] = []
    public var recentlyPerformedShows: [ShowWithArtist] = []
    
    public var allArtists: [ArtistWithCounts] = []
    public var featuredArtists: [ArtistWithCounts] = []
    
    public let recentlyPerformedNode: HorizontalShowCollectionCellNode
    public let allRecentlyUpdatedNode: HorizontalShowCollectionCellNode
    
    public var resourceRecentlyPerformed: Resource? = nil
    public let resourceRecentlyUpdated: Resource
    
    public override var resultsViewController: UIViewController? { get { return ArtistsSearchResultsViewController(useCache: true, refreshOnAppear: true) } }
    
    var artistResults: ArtistsSearchResultsViewController {
        get {
            return resultsViewController as! ArtistsSearchResultsViewController
        }
    }
    
    public init() {
        recentlyPerformedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        allRecentlyUpdatedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        
        resourceRecentlyUpdated = RelistenApi.recentlyUpdated()
        
        super.init(useCache: true, refreshOnAppear: true, style: .plain, enableSearch: true)
        
        tabBarItem = UITabBarItem(title: "Relisten", image: UIImage(named: "toolbar_relisten"), tag: RelistenTabs.artistsOrPhish.rawValue)
        
        recentlyPerformedNode.collectionNode.delegate = self
        allRecentlyUpdatedNode.collectionNode.delegate = self
        
        resourceRecentlyUpdated.addObserver(self)
        resourceRecentlyUpdated.loadIfNeeded()
        
        let settingsItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(presentSettings(_:)))
        settingsItem.accessibilityLabel = "Settings"
        self.navigationItem.rightBarButtonItem = settingsItem
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Search Artists"
        searchController.searchBar.barStyle = .black
        searchController.searchBar.isTranslucent = true
        searchController.searchBar.backgroundColor = AppColors.primary
        searchController.searchBar.barTintColor = AppColors.textOnPrimary
        searchController.searchBar.tintColor = AppColors.textOnPrimary
        
        //queue issue fix from: https://stackoverflow.com/questions/58287304/how-to-change-text-color-of-placeholder-in-uisearchbar-ios-13
        let placeholder = NSAttributedString(string: "Search Artists",
                                             attributes: [
                                                .foregroundColor: AppColors.textOnPrimary.withAlphaComponent(0.80)
        ])
        let searchTextField = searchController.searchBar.searchTextField
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                searchTextField.leftView?.tintColor = AppColors.textOnPrimary
                searchTextField.attributedPlaceholder = placeholder
            }
        }
        
        artistResults.tableNode.delegate = self
        
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Relisten"
        
        let library = MyLibrary.shared
        
        library.favorites.artists.observeWithValue { [weak self] artists, changes in
            guard let s = self else { return }
            
            s.reloadFavoriteArtists(artists: artists, changes: changes)
        }.dispose(to: &disposal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppColors_SwitchToRelisten()
    }
    
    // MARK: State Restoration
    static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        let vc = ArtistsViewController()
        return vc
    }
    
    private func modelIdentifierForElement(at indexPath: IndexPath) -> String? {
        let row = indexPath.row
        
        switch Sections(rawValue: indexPath.section)! {
        case .recentlyPerformed:
            return "RecentlyPerformedShows"
        case .allRecentlyUpdated:
            return "RecentlyUpdatedShows"
            
        case .favorited:
            let artist = allArtists.first(where: { art in art.uuid == favoriteArtists[row] })!
            return "FavoritedArtists.\(artist.uuid)"
        case .featured:
            let artist = featuredArtists[row]
            return "FeaturedArtists.\(artist.uuid)"
        case .all:
            let artist = allArtists[indexPath.row]
            return "AllArtists.\(artist.uuid)"
        case .count:
            fatalError()
        }
    }
    
    private func indexPathForElement(withModelIdentifier identifier: String) -> IndexPath? {
        switch identifier {
        case "RecentlyPerformedShows":
            return IndexPath(row: 0, section: Sections.recentlyPerformed.rawValue)
        case "RecentlyUpdatedShows":
            return IndexPath(row: 0, section: Sections.allRecentlyUpdated.rawValue)
        default:
            // (farkas) TODO: Compute the row from the artist UUID
            if identifier.hasPrefix("FavoritedArtists") {
                return IndexPath(row: 0, section: Sections.favorited.rawValue)
            } else if identifier.hasPrefix("FeaturedArtists") {
                return IndexPath(row: 0, section: Sections.featured.rawValue)
            } else if identifier.hasPrefix("AllArtists") {
                return IndexPath(row: 0, section: Sections.all.rawValue)
            }
        }
        
        return nil
    }
    
    override open func modelIdentifierForElement(at indexPath: IndexPath, in tableNode: ASTableNode) -> String? {
        return modelIdentifierForElement(at: indexPath)
    }
    
    override open func indexPathForElement(withModelIdentifier identifier: String, in tableNode: ASTableNode) -> IndexPath? {
        return indexPathForElement(withModelIdentifier: identifier)
    }
    
    // MARK: Loading Data
    @objc func presentSettings(_ sender: UINavigationBar?) {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }
    
    override func has(oldData old: [ArtistWithCounts], changed new: [ArtistWithCounts]) -> Bool {
        return old.count != new.count
    }
    
    override func dataChanged(_ data: [ArtistWithCounts]) {
        self.allArtists = data
        self.featuredArtists = data.filter({ $0.featured > 0 })
        
        super.dataChanged(data)
    }
    
    override var resource: Resource? { get { return api.artists() } }
    
    private func reloadFavoriteArtists(artists: Results<FavoritedArtist>, changes: RealmCollectionChange<Results<FavoritedArtist>>) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            
            let previousFavoriteCount = s.favoriteArtists.count
            let localFavoriteArtists = Array(artists.compactMap({ UUID(uuidString: $0.artist_uuid) }))
            
            let newFavoriteCount = localFavoriteArtists.count
            
            switch changes {
            case .initial:
                s.tableNode.performBatch(animated: true, updates: {
                    s.favoriteArtists = localFavoriteArtists
                    s.resourceRecentlyPerformed?.loadIfNeeded()
                    //Have favorites on launch?
                    if MyLibrary.shared.favorites.artists.count > 0 {
                        s.resourceRecentlyPerformed = RelistenApi.recentlyPerformed(byArtists: s.favoriteArtists)
                        s.resourceRecentlyPerformed?.addObserver(s)
                        s.resourceRecentlyPerformed?.loadFromCacheThenUpdate()
                    }
                    s.tableNode.reloadSections(IndexSet(integer: Sections.favorited.rawValue), with: .automatic)
                    s.tableNode.reloadSections(IndexSet(integer: Sections.allRecentlyUpdated.rawValue), with: .automatic)
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
    
    // MARK: Search
    public override func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        artistResults.favoriteArtists = favoriteArtists        
        self.artistResults.filteredArtists = self.allArtists.filter({ $0.name.lowercased().contains(searchText) })
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
            
            if resource == self.resourceRecentlyPerformed {
                self.recentlyPerformedShows = resource.typedContent(ifNone: [])
                self.recentlyPerformedNode.shows = self.recentlyPerformedShows.map { (show: $0, artist: $0.artist, nil) }
                self.render()
            }
            else if resource == self.resourceRecentlyUpdated {
                self.allRecentlyUpdatedShows = resource.typedContent(ifNone: [])
                self.allRecentlyUpdatedNode.shows = self.allRecentlyUpdatedShows.map { (show: $0, artist: $0.artist, nil) }
                self.render()
            }
        }
        else {
            super.resourceChanged(resource, event: event)
        }
    }
    
    // MARK: UITableViewDataSource
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .favorited:
            return allArtists.count == 0 ? 0 : favoriteArtists.count
        case .featured:
            return featuredArtists.count
        case .all:
            return allArtists.count
        case .recentlyPerformed:
            return recentlyPerformedShows.count > 0 ? 1 : 0
        case .allRecentlyUpdated:
            return allRecentlyUpdatedShows.count > 0 ? 1 : 0
        case .count:
            fatalError()
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let row = indexPath.row
        
        switch Sections(rawValue: indexPath.section)! {
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
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if tableNode == self.artistResults.tableNode {
            var artist : ArtistWithCounts? = nil
            tableUpdateQueue.sync {
                artist = self.artistResults.filteredArtists[indexPath.row]
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
        switch Sections(rawValue: section)! {
        case .favorited:
            return favoriteArtists.count > 0 ? "Favorite" : nil
        case .featured:
            return "Featured"
        case .all:
            if let artists = latestData {
                return "All \(artists.count) Artists"
            }
            
            return "All Artists"
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
