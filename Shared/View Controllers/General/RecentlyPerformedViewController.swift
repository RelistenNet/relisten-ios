//
//  RecentlyPerformedViewController.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/22/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit

class RecentlyPerformedViewController: ShowListViewController<[Show]> {
    // Show all shows performed in the last three months
    private let recentShowInterval : TimeInterval = (60 * 60 * 24 * 30 * 3)
    
    public required init(artist: Artist, tourSections: Bool, enableSearch: Bool = true) {
        super.init(artist: artist, tourSections: tourSections, enableSearch: enableSearch)
        
        title = "Recently Performed"
    }
    
    public convenience init(artist: Artist) {
        self.init(artist: artist, tourSections: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return RelistenApi.recentlyPerformed(byArtist: artist)
        }
    }
    
    override func extractShowsAndSource(forData: [Show]) -> [ShowWithSingleSource] {
        let filteredShows = forData.filter { return ($0.date.timeIntervalSinceNow > -(recentShowInterval)) }
        return filteredShows.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    override func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show, showUpdateDate: false) }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
