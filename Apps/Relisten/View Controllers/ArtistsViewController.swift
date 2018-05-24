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
        if let data = latestData {
            let b = BatchUpdates()
            b.reloadSections.insert(0)
            
            layout(batchUpdates: b, layout: {
                return self.doLayout(forData: data)
            })
        }
    }
    
    func doLayout(forData: [ArtistWithCounts]) -> [Section<[Layout]>] {
        let favArtistIds = MyLibraryManager.shared.library.artistIds
        let toLayout : (ArtistWithCounts) -> ArtistLayout = { ArtistLayout(artist: $0, withFavoritedArtists: favArtistIds) }
    
        return [
            forData.filter({ favArtistIds.contains($0.id) }).sorted(by: { $0.name < $1.name }).map(toLayout).asSection("Favorites"),
            forData.filter({ $0.featured > 0 }).map(toLayout).asSection("Featured"),
            forData.map(toLayout).asSection("All \(forData.count) Artists")
        ]
    }

    override var resource: Resource? { get { return api.artists() } }
    
    override func render(forData: [ArtistWithCounts]) {
        layout {
            return self.doLayout(forData: forData)
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            let favArtistIds = MyLibraryManager.shared.library.artistIds
            
            var artist: ArtistWithCounts
            if indexPath.section == 0 {
                artist = d.filter({ favArtistIds.contains($0.id) }).sorted(by: { $0.name < $1.name })[indexPath.row]
            }
            else if indexPath.section == 1 {
                artist = d.filter({ $0.featured > 0 })[indexPath.row]
            }
            else {
                artist = d[indexPath.row]
            }
            
            navigationController?.pushViewController(ArtistViewController(artist: artist), animated: true)
        }
    }
}
