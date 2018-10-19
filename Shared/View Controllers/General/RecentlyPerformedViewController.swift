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
    
    public required init(artist: Artist, showsResource: Resource?, tourSections: Bool) {
        super.init(artist: artist, showsResource: (showsResource != nil) ? showsResource : RelistenApi.recentlyAddedShows(byArtist: artist), tourSections: tourSections)
        
        title = "Recently Performed"
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
        let filteredShows = forData.filter { return ($0.date.timeIntervalSinceNow > -(recentShowInterval)) }
        return filteredShows.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    override func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show, showUpdateDate: false) }
    }
}
