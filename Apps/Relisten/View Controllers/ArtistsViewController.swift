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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Relisten"
    }

    override var resource: Resource? { get { return api.artists() } }
    
    override func render(forData: [ArtistWithCounts]) {
        layout {
            let toLayout : (ArtistWithCounts) -> ArtistLayout = { ArtistLayout(artist: $0) }
            
            return [
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
            navigationController?.pushViewController(ArtistViewController(artist: d[indexPath.row]), animated: true)
        }
    }
}
