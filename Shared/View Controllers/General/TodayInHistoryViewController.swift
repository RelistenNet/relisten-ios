//
//  TodayInHistoryViewController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/25/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import Siesta

class TodayInHistoryViewController: NewShowListArrayViewController<ShowWithArtist> {
    static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        return d
    }()
    
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(providedArtist: artist)
        
        title = "Shows on" + TodayInHistoryViewController.dateFormatter.string(from: Date())
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(providedArtist artist: ArtistWithCounts?, sort: ShowSorting, tourSections: Bool, artistSections: Bool, enableSearch: Bool) {
        fatalError("init(providedArtist:sort:tourSections:artistSections:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<[ShowWithArtist], ShowWithArtist, ShowListArrayDataSourceDefaultExtractor<ShowWithArtist>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return api.onThisDay(byArtist: artist)
        }
    }
    
    override func dataChanged(_ todayShows: [ShowWithArtist]) {
        super.dataChanged(todayShows)
        
        title = "\(todayShows.count) Show\(todayShows.count != 1 ? "s" : "") on " + TodayInHistoryViewController.dateFormatter.string(from: Date())
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
