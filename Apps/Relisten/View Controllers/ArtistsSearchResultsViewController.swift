//
//  ArtistsSearchResultsViewController.swift
//  Relisten
//
//  Created by Chris Paine on 3/14/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import UIKit
import RelistenShared

import AsyncDisplayKit

class ArtistsSearchResultsViewController: RelistenTableViewController<Any> {
    public var favoriteArtists: [UUID]!
    public var filteredArtists: [ArtistWithCounts] = [] {
        didSet {
            DispatchQueue.main.async {
                self.render()
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return filteredArtists.isEmpty ? 0 : 1
    }
    
    override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return filteredArtists.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        if let artist = filteredArtists.objectAtIndexIfInBounds(indexPath.row) {
            return { ArtistCellNode(artist: artist, withFavoritedArtists: self.favoriteArtists) }
        } else {
            fatalError("Couldn't get an artist at \(indexPath)")
        }
    }
}
