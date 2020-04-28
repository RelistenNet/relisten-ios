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

class RecentlyAddedViewController: NewShowListArrayViewController<Show> {
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(
            providedArtist: artist,
            sort: .noSorting,
            tourSections: false,
            artistSections: false,
            enableSearch: true
        )
        
        title = "Recently Added"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(enableSearch: Bool) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    public required init(providedArtist artist: ArtistWithCounts? = nil, sort: ShowSorting = .descending, tourSections: Bool = true, artistSections: Bool = false, enableSearch: Bool = true) {
        fatalError("init(providedArtist:sort:tourSections:artistSections:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<[Show], Show, ShowListArrayDataSourceDefaultExtractor<Show>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return RelistenApi.recentlyAddedShows(byArtist: artist)
        }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
