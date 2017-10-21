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
        
        artistIdChangedEventHandler = MyLibraryManager.sharedInstance.favoriteArtistIdsChanged.addHandler(target: self, handler: ArtistsViewController.favoritesChanged)
    }
    
    deinit {
        if let e = self.artistIdChangedEventHandler {
            e.dispose()
        }
    }
    
    func favoritesChanged(ids: Set<Int>) {
        render()
    }

    override var resource: Resource? { get { return api.artists() } }
    
    override func render(forData: [ArtistWithCounts]) {
        layout {
            let favArtistIds = MyLibraryManager.sharedInstance.artistIds
            let toLayout : (ArtistWithCounts) -> ArtistLayout = { ArtistLayout(artist: $0, withFavoritedArtists: favArtistIds) }
            
            return [
                forData.filter({ favArtistIds.contains($0.id) }).map(toLayout).asSection("Favorites"),
                forData.filter({ $0.featured > 0 }).map(toLayout).asSection("Featured"),
                forData.map(toLayout).asSection("All \(forData.count) Artists")
            ]
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            let favArtistIds = MyLibraryManager.sharedInstance.artistIds
            
            var artist: ArtistWithCounts
            if indexPath.section == 0 {
                artist = d.filter({ favArtistIds.contains($0.id) })[indexPath.row]
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
