//
//  VenuesViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Siesta
import AsyncDisplayKit
import SINQ

// TODO: Combine this with SongsViewController into something more abstract. The code is practically identical
class VenuesViewController: RelistenAsyncTableViewController<[VenueWithShowCount]> {
    let artist: ArtistWithCounts
    var venues: [Grouping<String, VenueWithShowCount>] = []
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Venues"
    }
    
    override var resource: Resource? { get { return api.venues(forArtist: artist) } }
    
    public override func dataChanged(_ data: [VenueWithShowCount]) {
        venues = sinq(data)
            .groupBy({
                return $0.sortName.groupNameForTableView()
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
        })
    }
    
    func venueForIndexPath(_ indexPath: IndexPath) -> VenueWithShowCount? {
        var retval : VenueWithShowCount? = nil
        if indexPath.section >= 0, indexPath.section < venues.count {
            let allVenues = venues[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allVenues.count() {
                retval = allVenues.elementAt(indexPath.row)
            }
        }
        return retval
    }
    
    //MARK: Table Data Source
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return venues.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return venues[section].values.count()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        return venues[section].key
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        if let venue = venueForIndexPath(indexPath) {
            return { VenueNode(venue: venue) }
        } else {
            return { ASCellNode() }
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if let venue = venueForIndexPath(indexPath) {
            navigationController?.pushViewController(VenueViewController(artist: artist, venue: venue), animated: true)
        }
    }
}
