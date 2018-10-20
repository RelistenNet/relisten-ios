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

class VenuesViewController: GroupedViewController<VenueWithShowCount> {
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
}
