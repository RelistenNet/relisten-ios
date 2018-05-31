//
//  ArtistsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import LayoutKit

class ArtistsViewController: RelistenTableViewController<[ArtistWithCounts]> {

    var artistIdChangedEventHandler: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Relisten"
        
        artistIdChangedEventHandler = MyLibraryManager.shared.favoriteArtistIdsChanged.addHandler(target: self, handler: ArtistsViewController.favoritesChanged)
        trackFinishedHandler = RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(target: self, handler: ArtistsViewController.relayoutIfContainsTrack)
        tracksDeletedHandler = RelistenDownloadManager.shared.eventTracksDeleted.addHandler(target: self, handler: ArtistsViewController.relayoutIfContainsTracks)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppColors_SwitchToRelisten(navigationController)
    }
    
    var trackFinishedHandler: Disposable?
    var tracksDeletedHandler: Disposable?
    
    deinit {
        for handler in [trackFinishedHandler, tracksDeletedHandler, artistIdChangedEventHandler] {
            handler?.dispose()
        }
    }
    
    func relayoutIfContainsTrack(_ track: CompleteTrackShowInformation) {
        render()
    }
    
    func relayoutIfContainsTracks(_ tracks: [CompleteTrackShowInformation]) {
        render()
    }
    
    func favoritesChanged(ids: Set<Int>) {
        render()
    }
    
    func doLayout(forData: [ArtistWithCounts]) -> [Section<[Layout]>] {
        let favArtistIds = MyLibraryManager.shared.library.artistIds
        let toLayout : (ArtistWithCounts) -> ArtistLayout = { ArtistLayout(artist: $0, withFavoritedArtists: favArtistIds) }
    
        var sections = [
//            forData.filter({ favArtistIds.contains($0.id) }).sorted(by: { $0.name < $1.name }).map(toLayout).asSection("Favorites"),
            forData.filter({ $0.featured > 0 }).map(toLayout).asSection("Featured"),
            forData.map(toLayout).asSection("All \(forData.count) Artists")
        ]
        
        if MyLibraryManager.shared.library.offlineSourcesMetadata.count > 0 {
            sections.insert(LayoutsAsSingleSection(items: [offlineLayout], title: "Downloaded Shows"), at: 0)
        }
        
        if MyLibraryManager.shared.library.recentlyPlayed.count > 0 {
            sections.insert(LayoutsAsSingleSection(items: [recentlyPlayedLayout], title: "Recently Played"), at: 0)
        }

        return sections
    }

    override var resource: Resource? { get { return api.artists() } }
    
    override func render(forData: [ArtistWithCounts]) {
        layout {
            return self.doLayout(forData: forData)
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        if let firstSub = cell.contentView.subviews.first, let _ = firstSub as? UICollectionView {
            cell.accessoryType = .none
        }
        else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            var artist: ArtistWithCounts
            
            /*
             let favArtistIds = MyLibraryManager.shared.library.artistIds
             
            if indexPath.section == 0 {
                artist = d.filter({ favArtistIds.contains($0.id) }).sorted(by: { $0.name < $1.name })[indexPath.row]
            }
            */
            
            var currentSection = 0
            
            if MyLibraryManager.shared.library.offlineSourcesMetadata.count > 0 {
                currentSection += 1
            }
            
            if MyLibraryManager.shared.library.recentlyPlayed.count > 0 {
                currentSection += 1
            }
                
            if indexPath.section == currentSection {
                artist = d.filter({ $0.featured > 0 })[indexPath.row]
            }
            else {
                artist = d[indexPath.row]
            }
            
            navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
        }
    }
    
    lazy var recentlyPlayedLayout: CollectionViewLayout = {
        return HorizontalShowCollection(
            withId: "recentlyPlayed",
            makeAdapater: { (collectionView) -> ReloadableViewLayoutAdapter in
                self.recentlyPlayedLayoutAdapter = CellSelectCallbackReloadableViewLayoutAdapter(reloadableView: collectionView) { indexPath in
                    let recent = MyLibraryManager.shared.library.recentlyPlayed
                    
                    if indexPath.item < recent.count {
                        let item = recent[indexPath.item]
                        let vc = SourcesViewController(artist: item.artist, show: item.show)
                        
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                    return true
                }
                return self.recentlyPlayedLayoutAdapter!
        }) { () -> [Section<[Layout]>] in
            let recent = MyLibraryManager.shared.library.recentlyPlayed
            
            let recentItems = recent.map({ YearShowLayout(show: $0.show, withRank: nil, verticalLayout: true, showingArtist: $0.artist) })
            return [LayoutsAsSingleSection(items: recentItems)]
        }
    }()
    var recentlyPlayedLayoutAdapter: ReloadableViewLayoutAdapter? = nil
    
    lazy var offlineLayout: CollectionViewLayout = {
        return HorizontalShowCollection(
            withId: "offline",
            makeAdapater: { (collectionView) -> ReloadableViewLayoutAdapter in
                self.offlineLayoutAdapter = CellSelectCallbackReloadableViewLayoutAdapter(reloadableView: collectionView) { indexPath in
                    let recent = MyLibraryManager.shared.library.offlineSourcesMetadata.sorted(by: { $0.dateAdded > $1.dateAdded })
                    
                    if indexPath.item < recent.count {
                        let item = recent[indexPath.item]
                        let vc = SourcesViewController(artist: item.artist, show: item.show)
                        
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                    return true
                }
                return self.offlineLayoutAdapter!
        }) { () -> [Section<[Layout]>] in
            let recent = MyLibraryManager.shared.library.offlineSourcesMetadata.sorted(by: { $0.dateAdded > $1.dateAdded })
            
            let recentItems = recent.map({ YearShowLayout(show: $0.show, withRank: nil, verticalLayout: true, showingArtist: $0.artist) })
            return [LayoutsAsSingleSection(items: recentItems)]
        }
    }()
    var offlineLayoutAdapter: ReloadableViewLayoutAdapter? = nil
}
