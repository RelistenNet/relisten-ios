//
//  TopShowsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class TopShowsViewController: RelistenTableViewController<[Show]> {
    
    let artist: SlimArtistWithFeatures
    
    public required init(artist: SlimArtistWithFeatures) {
        self.artist = artist
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Top Shows"
    }
    
    override var resource: Resource? { get { return api.topShows(byArtist: artist) } }
    
    override func render(forData: [Show]) {
        layout {
            return forData.enumerated().map { (idx: Int, show: Show) in
                return YearShowLayout(show: show, withRank: idx + 1)
            }.asTable()
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            navigationController?.pushViewController(SourcesViewController(artist: artist, show: d[indexPath.row]), animated: true)
        }
    }
}
