//
//  SongsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

class SongsViewController: GroupedViewController<SongWithShowCount> {
    override var scopeButtonTitles : [String]? { get { return ["All", "SBD", "Remast", "Downloaded"] } }
    override var searchPlaceholder : String { get { return "Search Songs" } }
    override var title: String? { get { return "Songs" } set { } }
    
    override var resource: Resource? { get { return api.songs(byArtist: artist) } }
    
    override func groupNameForItem(_ item: SongWithShowCount) -> String { return item.name.groupNameForTableView() }
    override func searchStringMatchesItem(_ item: SongWithShowCount, searchText: String) -> Bool { return item.name.lowercased().contains(searchText) }
    override func scopeMatchesItem(_ item: SongWithShowCount, scope: String) -> Bool { return (scope == "All") }
    
    override func cellNodeBlockForItem(_ item: SongWithShowCount) -> ASCellNodeBlock { return { SongNode(song: item) } }
    override func viewControllerForItem(_ item: SongWithShowCount) -> UIViewController { return SongViewController(artist: artist, song: item) }
    
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
