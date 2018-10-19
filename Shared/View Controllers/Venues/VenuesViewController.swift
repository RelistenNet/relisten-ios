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
    override var scopeButtonTitles : [String]? { get { return ["All", "SBD", "Remast", "Downloaded"] } }
    override var searchPlaceholder : String { get { return "Search Venues" } }
    override var title: String? { get { return "Venues" } set { } }
    
    override var resource: Resource? { get { return api.venues(forArtist: artist) } }
    
    override func groupNameForItem(_ item: VenueWithShowCount) -> String { return item.sortName.groupNameForTableView() }
    override func searchStringMatchesItem(_ item: VenueWithShowCount, searchText: String) -> Bool { return item.name.lowercased().contains(searchText) }
    override func scopeMatchesItem(_ item: VenueWithShowCount, scope: String) -> Bool { return (scope == "All") }
    
    override func cellNodeBlockForItem(_ item: VenueWithShowCount) -> ASCellNodeBlock { return { VenueCellNode(venue: item, forArtist: self.artist) } }
    override func viewControllerForItem(_ item: VenueWithShowCount) -> UIViewController { return VenueViewController(artist: artist, venue: item) }
    
    //MARK: AsyncDisplayKit Stupidity
    override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return super.numberOfSections(in: tableNode)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return super.sectionIndexTitles(for: tableView)
    }
    
    override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return super.tableNode(tableNode, numberOfRowsInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    override func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        return super.tableNode(tableNode, didSelectRowAt: indexPath)
    }
}
