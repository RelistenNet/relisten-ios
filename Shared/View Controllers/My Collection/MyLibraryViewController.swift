//
//  File.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta

class MyLibraryViewController: ShowListViewController<[CompleteShowInformation]> {
    public required init(artist: ArtistWithCounts) {
        super.init(artist: artist, showsResource: nil, tourSections: true)
        
        title = "My Library"
        
        latestData = loadMyShows()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func relayoutIfContainsTrack(_ track: CompleteTrackShowInformation) {
        latestData = loadMyShows()
        
        super.relayoutIfContainsTrack(track)
    }
    
    override func relayoutIfContainsTracks(_ tracks: [CompleteTrackShowInformation]) {
        latestData = loadMyShows()
        
        super.relayoutIfContainsTracks(tracks)
    }
    
    override func extractShows(forData: [CompleteShowInformation]) -> [Show] {
        return forData.map({ $0.show })
    }
    
    func loadMyShows() -> [CompleteShowInformation] {
        return MyLibraryManager.shared.library.favoritedShowsPlayedByArtist(artist)
    }
}
