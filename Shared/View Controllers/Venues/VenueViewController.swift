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

class VenueViewController: ShowListViewController<VenueWithShows> {
    let venue: Venue
    
    public required init(artist: Artist, venue: Venue) {
        self.venue = venue
        
        super.init(
            artist: artist,
            showsResource: RelistenApi.shows(atVenue: venue, byArtist: artist),
            tourSections: false
        )
        
        title = venue.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override func extractShowsAndSource(forData:VenueWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
