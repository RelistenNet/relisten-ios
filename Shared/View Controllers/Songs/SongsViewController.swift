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
}
