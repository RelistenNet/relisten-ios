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

class ShowListYearDataSourceExtractor : ShowListWrappedArrayDataSourceExtractor<YearWithShows, Show> {
    public override func extractShowList(forData wrapper: YearWithShows) -> [Show] {
        return wrapper.shows
    }
}

public class YearViewController: NewShowListWrappedArrayViewController<YearWithShows, Show> {
    let year: Year
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts, year: Year) {
        self.year = year
        self.artist = artist
        
        super.init(
            extractor: ShowListYearDataSourceExtractor(providedArtist: artist),
            tourSections: true
        )
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    public required init(extractor: ShowListWrappedArrayDataSourceExtractor<YearWithShows, Show>, sort: ShowSorting = .descending, tourSections: Bool = true, artistSections: Bool = false, enableSearch: Bool = true) {
        fatalError("init(extractor:sort:tourSections:artistSections:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<YearWithShows, Show, ShowListWrappedArrayDataSourceExtractor<YearWithShows, Show>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return api.shows(inYear: year, byArtist: artist)
        }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
