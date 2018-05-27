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
import LayoutKit
import SINQ

class VenueViewController: ShowListViewController<VenueWithShows> {
    let venue: Venue
    
    public required init(artist: SlimArtistWithFeatures, venue: Venue) {
        self.venue = venue
        
        super.init(
            artist: artist,
            showsResource: RelistenApi.shows(atVenue: venue, byArtist: artist),
            tourSections: false
        )
        
        title = venue.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override func extractShows(forData: VenueWithShows) -> [Show] {
        return forData.shows
    }
}
