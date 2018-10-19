//
//  MyRecentlyPlayedViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import AsyncDisplayKit
import RealmSwift

class MyRecentlyPlayedViewController: ShowListViewController<Results<RecentlyPlayedTrack>> {
    public required init(artist: ArtistWithCounts) {
        super.init(artist: artist, showsResource: nil, tourSections: true)
        
        title = "My Recently Played"
        
        latestData = loadMyShows()
        
        MyLibrary.shared.recent.shows(byArtist: artist).observeWithValue { [weak self] _, changes in
            guard let s = self else { return }
            
            let myShows = s.loadMyShows()
            if myShows != s.latestData {
                s.latestData = myShows
                s.render()
            }
        }.dispose(to: &disposal)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func relayoutIfContainsTrack(_ track: Track) {
        latestData = loadMyShows()
        
        super.relayoutIfContainsTrack(track)
    }
    
    override func relayoutIfContainsTracks(_ tracks: [Track]) {
        latestData = loadMyShows()
        
        super.relayoutIfContainsTracks(tracks)
    }
    
    override func extractShowsAndSource(forData: Results<RecentlyPlayedTrack>) -> [ShowWithSingleSource] {
        return forData.asCompleteShows().map({ ShowWithSingleSource(show: $0.show, source: $0.source) })
    }
    
    func loadMyShows() -> Results<RecentlyPlayedTrack> {
        return MyLibrary.shared.recent.shows(byArtist: artist)
    }
}
