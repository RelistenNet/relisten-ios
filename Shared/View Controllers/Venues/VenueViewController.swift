//
//  VenueViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

class ShowListVenueDataSourceExtractor : ShowListWrappedArrayDataSourceExtractor<VenueWithShows, Show> {
    public override func extractShowList(forData wrapper: VenueWithShows) -> [Show] {
        return wrapper.shows
    }
}

class VenueViewController: NewShowListWrappedArrayViewController<VenueWithShows, Show> {
    let venue: Venue
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts, venue: Venue) {
        self.venue = venue
        self.artist = artist
        
        super.init(
            extractor: ShowListVenueDataSourceExtractor(providedArtist: artist),
            sort: .descending,
            tourSections: false,
            artistSections: false,
            enableSearch: true
        )
        
        title = venue.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    public required init(extractor: ShowListWrappedArrayDataSourceExtractor<VenueWithShows, Show>, sort: ShowSorting = .descending, tourSections: Bool = true, artistSections: Bool = false, enableSearch: Bool = true) {
        fatalError("init(extractor:sort:tourSections:artistSections:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<VenueWithShows, Show, ShowListWrappedArrayDataSourceExtractor<VenueWithShows, Show>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    override public var resource: Resource? {
        get {
            return RelistenApi.shows(atVenue: venue, byArtist: artist)
        }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
