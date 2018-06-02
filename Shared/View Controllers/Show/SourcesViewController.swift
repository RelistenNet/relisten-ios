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
import AsyncDisplayKit
import SINQ

class SourcesViewController: RelistenAsyncTableController<ShowWithSources> {
    
    let artist: ArtistWithCounts
    let show: Show?
    let isRandom: Bool
    
    var sources: [SourceFull] = []
    
    public required init(artist: ArtistWithCounts, show: Show) {
        self.artist = artist
        self.show = show
        self.isRandom = false
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    public required init(artist: ArtistWithCounts) {
        self.show = nil
        self.artist = artist
        self.isRandom = true
        
        super.init(useCache: false, refreshOnAppear: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle(forShow: show)
    }
    
    func updateTitle(forShow: Show?) {
        if let s = forShow {
            title = "\(s.display_date) Sources"
        }
    }
    
    override var resource: Resource? {
        get {
            return self.show == nil ? api.randomShow(byArtist: artist) : api.showWithSources(forShow: show!, byArtist: artist)
        }
    }
    
    override func dataChanged(_ data: ShowWithSources) {
        sources = data.sources
        updateTitle(forShow: data)
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return sources.count > 0 ? 1 : 0
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return sources.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let show = latestData else { return { ASCellNode() } }
        
        let source = sources[indexPath.row]
        let artist = self.artist
        
        return { SourceDetailsNode(source: source, inShow: show, artist: artist, atIndex: indexPath.row, isDetails: false) }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        guard let show = latestData else { return }

        let vc = SourceViewController(artist: artist, show: show, source: sources[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
