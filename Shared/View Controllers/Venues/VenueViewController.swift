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

class VenueViewController: ShowListViewController<VenueWithShows>, UIViewControllerRestoration {
    let venue: Venue
    
    public required init(artist: Artist, venue: Venue) {
        self.venue = venue
        
        super.init(
            artist: artist,
            tourSections: false
        )
        
        self.restorationIdentifier = "net.relisten.VenueViewController.\(artist.slug).\(venue.upstream_identifier)"
        self.restorationClass = type(of: self)
        
        title = venue.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override public var resource: Resource? {
        get {
            return RelistenApi.shows(atVenue: venue, byArtist: artist)
        }
    }
    
    override func extractShowsAndSource(forData:VenueWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil, artist: artist) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case venue = "venue"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: ShowListViewController<YearWithShows>.CodingKeys.artist.rawValue) as? Data,
                let venueData = coder.decodeObject(forKey: CodingKeys.venue.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let encodedVenue = try JSONDecoder().decode(Venue.self, from: venueData)
                let vc = VenueViewController(artist: encodedArtist, venue: encodedVenue)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let encodedVenue = try JSONEncoder().encode(self.venue)
            coder.encode(encodedVenue, forKey: CodingKeys.venue.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}
