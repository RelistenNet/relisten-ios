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
import LayoutKit
import SINQ

class TopShowsViewController: ShowListViewController<[Show]> {
    
    public required init(artist: SlimArtistWithFeatures) {
        super.init(
            artist: artist,
            showsResource: RelistenApi.topShows(byArtist: artist),
            tourSections: false
        )
        
        title = "Top Shows"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override func has(oldData: [Show], changed: [Show]) -> Bool {
        return true
    }
    
    override func layout(show: Show, atIndex: IndexPath) -> Layout {
        return YearShowLayout(show: show, withRank: atIndex.row + 1, verticalLayout: false)
    }
    
    override func extractShows(forData: [Show]) -> [Show] {
        return forData
    }
}
