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

class SongsViewController: GroupedViewController<[SongWithShowCount], SongWithShowCount> {
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
    
    override var searchPlaceholder : String { get { return "Search Songs" } }
    override var title: String? { get { return "Songs" } set { } }
    
    override var resource: Resource? { get { return api.songs(byArtist: artist) } }
    
    override func groupNameForItem(_ item: SongWithShowCount) -> String {
        return item.sortName.groupNameForTableView()
    }
    
    override func searchStringMatchesItem(_ item: SongWithShowCount, searchText: String) -> Bool {
        return item.name.lowercased().contains(searchText)
    }

    override func cellNodeBlockForItem(_ item: SongWithShowCount) -> ASCellNodeBlock {
        return { SongNode(song: item) }
    }
    
    override func viewControllerForItem(_ item: SongWithShowCount) -> UIViewController {
        return SongViewController(artist: artist, song: item)
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
