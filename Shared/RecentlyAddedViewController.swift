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
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override func extractShowsAndSource(forData: [Show]) -> [ShowWithSingleSource] {
        return forData.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    override func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show, showUpdateDate: true) }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
