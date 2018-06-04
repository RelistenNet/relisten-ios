//
//  ArtistsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit

class ArtistsViewController: RelistenAsyncTableController<[ArtistWithCounts]>, ASCollectionDelegate {
    enum Sections: Int, RawRepresentable {
        case recentlyPlayed = 0
        case availableOffline
        case favorited
        case featured
        case all
        case count
    }
    
    public var recentlyPlayed: [CompleteTrackShowInformation] = []
    public var favoriteArtists: [Int] = []
    public var offlineShows: Set<OfflineSourceMetadata> = []
    
    public var allArtists: [ArtistWithCounts] = []
    public var featuredArtists: [ArtistWithCounts] = []
    
    public let recentShowsNode: HorizontalShowCollectionCellNode
    public let offlineShowsNode: HorizontalShowCollectionCellNode

    public init() {
        recentShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        offlineShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)

        super.init(useCache: true, refreshOnAppear: true)
        
        recentShowsNode.collectionNode.delegate = self
        offlineShowsNode.collectionNode.delegate = self
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
        
        RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(cb).add(to: &disposal)
        RelistenDownloadManager.shared.eventTracksDeleted.addHandler(cb).add(to: &disposal)

        MyLibraryManager.shared.observeFavoriteArtistIds
            .observe({ [weak self] artistIds, _ in
                DispatchQueue.main.async {
                    self?.favoriteArtists = Array(artistIds);
                    self?.tableNode.reloadSections([ Sections.favorited.rawValue ], with: .automatic)
                }
            })
            .add(to: &disposal)
        
        MyLibraryManager.shared.observeRecentlyPlayedShows
            .observe({ [weak self] shows, _ in
                DispatchQueue.main.async {
                    self?.recentlyPlayed = shows
                    self?.tableNode.reloadSections([ Sections.recentlyPlayed.rawValue ], with: .automatic)
                }
                
                if let s = self {
                    s.recentShowsNode.shows = s.recentlyPlayed.map({ ($0.show, $0.artist) })
                }
            })
            .add(to: &disposal)
        
        MyLibraryManager.shared.library.observeOfflineSources
            .observe({ [weak self] shows, _ in
                DispatchQueue.main.async {
                    self?.offlineShows = shows
                    self?.tableNode.reloadSections([ Sections.availableOffline.rawValue ], with: .automatic)
                }
                
                if let s = self {
                    s.offlineShowsNode.shows = s.offlineShows.map({ ($0.show, $0.artist) })
                }
            })
            .add(to: &disposal)
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
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .recentlyPlayed:
            return recentlyPlayed.count > 0 ? 1 : 0
        case .availableOffline:
            return offlineShows.count > 0 ? 1 : 0
        case .favorited:
            return favoriteArtists.count
        case .featured:
            return featuredArtists.count
        case .all:
            return allArtists.count
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
        case .favorited:
            let artist = allArtists.first(where: { art in art.id == favoriteArtists[row] })!
            
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
            let artist = allArtists.first(where: { art in art.id == favoriteArtists[row] })!
            
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
            return recentlyPlayed.count > 0 ? "Recently Played" : nil
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
        default:
            return nil
        }
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let show: CompleteShowInformation?
        
        if collectionNode === recentShowsNode.collectionNode {
            show = recentlyPlayed[indexPath.item].toCompleteShowInformation()
        }
        else if collectionNode === offlineShowsNode.collectionNode {
            show = Array(offlineShows)[indexPath.item].completeShowInformation
        }
        else {
            show = nil
        }
        
        if let s = show {
            navigationController?.pushViewController(SourcesViewController(artist: s.artist, show: s.show), animated: true)
        }
    }
}
