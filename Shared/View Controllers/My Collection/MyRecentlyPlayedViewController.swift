//
//  MyRecentlyPlayedViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit
import RealmSwift

class MyRecentlyPlayedViewController: ShowListViewController<Results<RecentlyPlayedTrack>> {
    public required init(artist: ArtistWithCounts) {
        super.init(artist: artist, tourSections: true)
        
        title = "My Recently Played"
        
        latestData = loadMyShows()
        
        MyLibrary.shared.recent.shows(byArtist: artist).observeWithValue { [weak self] _, changes in
            guard let s = self else { return }
            
            let myShows = s.loadMyShows()
            if myShows != s.latestData {
                s.loadData(myShows)
            }
        }.dispose(to: &disposal)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func extractShowsAndSource(forData: Results<RecentlyPlayedTrack>) -> [ShowWithSingleSource] {
        return forData.asCompleteShows(toIndex: -1).map({ ShowWithSingleSource(show: $0.show, source: $0.source) })
    }
    
    func loadMyShows() -> Results<RecentlyPlayedTrack> {
        return MyLibrary.shared.recent.shows(byArtist: artist)
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
