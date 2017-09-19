//
//  SourcesViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class SourcesViewController: RelistenTableViewController<ShowWithSources> {
    
    let artist: SlimArtistWithFeatures
    let show: Show?
    let isRandom: Bool
    
    public required init(artist: SlimArtistWithFeatures, show: Show) {
        self.artist = artist
        self.show = show
        self.isRandom = false
        
        super.init()
    }
    
    public required init(artist: SlimArtistWithFeatures) {
        self.show = nil
        self.artist = artist
        self.isRandom = true
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle()
    }
    
    func updateTitle() {
        if let s = show {
            title = "\(s.display_date) Sources"
        }
    }
    
    override var resource: Resource? {
        get {
            return self.show == nil ? api.randomShow(byArtist: artist) : api.showWithSources(forShow: show!, byArtist: artist)
        }
    }
    
    override func render(forData: ShowWithSources) {
        layout {
            return forData.sources.enumerated().map { (idx, src) in SourceLayout(source: src, idx: idx, sourceCount: forData.sources.count) }.asTable()
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            navigationController?.pushViewController(SourceViewController(artist: artist, show: d, source: d.sources[indexPath.row]), animated: true)
        }
    }
}
