//
//  YearViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit
import Siesta
import AsyncDisplayKit

public class YearViewController: ShowListViewController<YearWithShows> {
    let year: Year
    
    public required init(artist: ArtistWithCounts, year: Year) {
        self.year = year
        
        super.init(artist: artist, tourSections: true)
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return RelistenApi.shows(inYear: year, byArtist: artist)
        }
    }
    
    public override func extractShowsAndSource(forData: YearWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
