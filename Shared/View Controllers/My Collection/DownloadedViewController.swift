//
//  DownloadedViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit

class DownloadedViewController: ShowListViewController<[CompleteShowInformation]> {
    public required init(artist: ArtistWithCounts) {
        super.init(artist: artist, showsResource: nil, tourSections: true)
        
        refreshOnAppear = true
        title = "Downloaded Shows"
        
        latestData = loadOffline()
        
        MyLibrary.shared.offline.sources(byArtist: artist).observeWithValue { [weak self] (os, changes) in
            guard let s = self else { return }
            
            let offlineSources = os.asCompleteShows()
            if !(offlineSources == s.latestData) {
                s.latestData = offlineSources
                s.render()
            }
        }.dispose(to: &disposal)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func relayoutIfContainsTrack(_ track: Track) {
        latestData = loadOffline()
        
        super.relayoutIfContainsTrack(track)
    }
    
    override func relayoutIfContainsTracks(_ tracks: [Track]) {
        latestData = loadOffline()
        
        super.relayoutIfContainsTracks(tracks)
    }
    
    override func extractShowsAndSource(forData data: [CompleteShowInformation]) -> [ShowWithSingleSource] {
        return data.map({ ShowWithSingleSource(show: $0.show, source: $0.source) })
    }
    
    func loadOffline() -> [CompleteShowInformation] {
        return MyLibrary.shared.offline.sources(byArtist: artist).asCompleteShows()
    }
    
    // This subclass has to re-implement this method because Texture tries to perform an Obj-C respondsToSelctor: check and it's not finding the methods if they just exist on the superclass with the argument label names (numberOfSectionsIn: does exist though)
    override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return super.numberOfSections(in: tableNode)
    }
    
    override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return super.tableNode(tableNode, numberOfRowsInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        return super.tableNode(tableNode, didSelectRowAt: indexPath)
    }
}
