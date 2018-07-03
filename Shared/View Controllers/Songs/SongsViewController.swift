//
//  SongsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class SongsViewController: RelistenTableViewController<[SongWithShowCount]> {
    
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Songs"
    }
    
    override func has(oldData: [SongWithShowCount], changed: [SongWithShowCount]) -> Bool {
        return oldData.count != changed.count
    }
    
    override var resource: Resource? { get { return api.songs(byArtist: artist) } }
    
    var groups: [Grouping<String, SongWithShowCount>]? = nil
    
    override func render(forData: [SongWithShowCount]) {
        groups = sinq(forData)
            .groupBy({
                return $0.sortName.groupNameForTableView()
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })
        
        layout {
            guard let g = self.groups else {
                return [Section(header: nil, items: [], footer: nil)]
            }
            
            return g.map {
                LayoutsAsSingleSection(items: $0.values.map({ (v) in
                    return SongLayout(song: v)
                }), title: $0.key as String?)
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let g = groups {
            return g.map({ $0.key })
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let g = groups {
            let s = g[indexPath.section].values.elementAt(indexPath.row)
            navigationController?.pushViewController(SongViewController(artist: artist, song: s), animated: true)
        }
    }
}
