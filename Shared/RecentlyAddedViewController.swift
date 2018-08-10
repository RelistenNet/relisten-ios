//
//  RecentlyAddedViewController.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/22/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit

class RecentlyAddedViewController: ShowListViewController<[Show]> {
    public required init(artist: Artist, showsResource: Resource?, tourSections: Bool) {
        super.init(artist: artist, showsResource: (showsResource != nil) ? showsResource : RelistenApi.recentlyAddedShows(byArtist: artist), tourSections: tourSections)

        shouldSortShows = false
        title = "Recently Added"
    }
    
    public convenience init(artist: Artist) {
        self.init(artist: artist, showsResource: RelistenApi.recentlyAddedShows(byArtist: artist), tourSections: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override func extractShowsAndSource(forData: [Show]) -> [ShowWithSingleSource] {
        return forData.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    override func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show, showUpdateDate: true) }
    }
    
    // MARK: Boring Overrides
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
