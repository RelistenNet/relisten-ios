//
//  SourceViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 6/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class SourceViewController: RelistenBaseTableViewController {
    
    let artist: SlimArtistWithFeatures
    let show: ShowWithSources
    let source: SourceFull
    let idx: Int
    
    public required init(artist: SlimArtistWithFeatures, show: ShowWithSources, source: SourceFull) {
        self.artist = artist
        self.show = show
        self.source = source
        
        var idx = 0
        
        for src in show.sources {
            if self.source.id == src.id {
                break
            }
            idx += 1
        }
        
        self.idx = idx
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(show.display_date) #\(idx + 1)"
        
        layout {
            var sections: [Section<[Layout]>] = [ Section(items: [ SourceDetailsLayout(source: self.source, inShow: self.show, artist: self.artist, atIndex: self.idx) ]) ]
            
            sections.append(contentsOf: self.source.sets.map({ (set: SourceSet) -> Section<[Layout]> in
                let layouts = set.tracks.map({ TrackStatusLayout(forTrack: TrackStatus(forTrack: $0), inSource: self.source, byArtist: self.artist) })
                return LayoutsAsSingleSection(items: layouts, title: self.artist.features.sets ? set.name : "Tracks")
            }))
            
            return sections
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //if let d = latestData {
            //navigationController?.pushViewController(YearViewController(artist: artist, year: d[indexPath.row]), animated: true)
        //}
    }
}
