//
//  TopShowsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

class TopShowsViewController: ShowListViewController<[Show]>, UIViewControllerRestoration {
    public required init(artist: Artist) {
        super.init(
            artist: artist,
            tourSections: false
        )
        
        self.restorationIdentifier = "net.relisten.TopShowsViewController.\(artist.slug)"
        self.restorationClass = type(of: self)
        
        shouldSortShows = false
        title = "Top Shows"
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
    
    public override var resource: Resource? {
        get {
            return RelistenApi.topShows(byArtist: artist)
        }
    }
        
    override func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show, withRank: atIndex.row + 1, useCellLayout: false) }
    }
    
    override func extractShowsAndSource(forData: [Show]) -> [ShowWithSingleSource] {
        return forData.map({ ShowWithSingleSource(show: $0, source: nil, artist: artist) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    //MARK: State restoration
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        do {
            if let artistData = coder.decodeObject(forKey: ShowListViewController<Any>.CodingKeys.artist.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let vc = TopShowsViewController(artist: encodedArtist)
                return vc
            }
        } catch { }
        return nil
    }
}
