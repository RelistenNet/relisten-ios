//
//  MyLibraryViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit

class MyLibraryViewController: ShowListViewController<[CompleteShowInformation]> {
    public required init(artist: ArtistWithCounts) {
        super.init(artist: artist, showsResource: nil, tourSections: true)
        
        title = "My Library"
        
        latestData = loadMyShows()
        
        MyLibraryManager.shared.observeMyShows.observe { [weak self] (_, _) in
            let myShows = self?.loadMyShows()
            if !(myShows == self?.latestData) {
                self?.latestData = myShows
                self?.render()
            }
        }.add(to: &disposal)
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
        latestData = loadMyShows()
        
        super.relayoutIfContainsTrack(track)
    }
    
    override func relayoutIfContainsTracks(_ tracks: [Track]) {
        latestData = loadMyShows()
        
        super.relayoutIfContainsTracks(tracks)
    }
    
    override func extractShowsAndSource(forData: [CompleteShowInformation]) -> [ShowWithSingleSource] {
        return forData.map({ ShowWithSingleSource(show: $0.show, source: $0.source) })
    }
    
    func loadMyShows() -> [CompleteShowInformation] {
        return MyLibraryManager.shared.library.favoritedShowsPlayedByArtist(artist)
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
