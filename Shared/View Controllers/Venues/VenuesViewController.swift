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

class VenuesViewController: GroupedViewController<[VenueWithShowCount], VenueWithShowCount> {
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts, enableSearch: Bool = true) {
        self.artist = artist
        
        super.init(enableSearch: enableSearch)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    override var searchPlaceholder : String { get { return "Search Venues" } }
    override var title: String? { get { return "Venues" } set { } }
    
    override var resource: Resource? { get { return api.venues(forArtist: artist) } }
    
    override func groupNameForItem(_ item: VenueWithShowCount) -> String { return item.sortName.groupNameForTableView() }
    override func searchStringMatchesItem(_ item: VenueWithShowCount, searchText: String) -> Bool {
        if item.name.lowercased().contains(searchText) {
            return true
        }
        if item.location.lowercased().contains(searchText) {
            return true
        }
        if let pastNames = item.past_names,
           pastNames.lowercased().contains(searchText) {
            return true
        }
        return false
    }
    
    override func cellNodeBlockForItem(_ item: VenueWithShowCount) -> ASCellNodeBlock { return { VenueCellNode(venue: item, forArtist: self.artist) } }
    override func viewControllerForItem(_ item: VenueWithShowCount) -> UIViewController { return VenueViewController(artist: artist, venue: item) }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
