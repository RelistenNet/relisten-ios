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
    
    public required init(artist: ArtistWithCounts, venue: Venue) {
        self.venue = venue
        
        super.init(
            artist: artist,
            showsResource: RelistenApi.shows(atVenue: venue, byArtist: artist),
            tourSections: false
        )
        
        title = venue.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
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
    
    override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return super.numberOfSections(in: tableNode)
    }
    
    override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return super.tableNode(tableNode, numberOfRowsInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        return super.tableNode(tableNode, didSelectRowAt: indexPath)
    }
}
