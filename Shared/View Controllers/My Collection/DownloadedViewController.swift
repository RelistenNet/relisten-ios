//
//  DownloadedViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta

class DownloadedViewController: ShowListViewController<[OfflineSourceMetadata]> {
    public required init(artist: SlimArtistWithFeatures) {
        super.init(artist: artist, showsResource: nil, tourSections: true)
        
        refreshOnAppear = true
        title = "Downloaded Shows"
        
        latestData = loadOffline()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func relayoutIfContainsTrack(_ track: CompleteTrackShowInformation) {
        latestData = loadOffline()
        
        super.relayoutIfContainsTrack(track)
    }
    
    override func relayoutIfContainsTracks(_ tracks: [CompleteTrackShowInformation]) {
        latestData = loadOffline()
        
        super.relayoutIfContainsTracks(tracks)
    }
    
    override func extractShows(forData: [OfflineSourceMetadata]) -> [Show] {
        return forData.map({ $0.show })
    }
    
    func loadOffline() -> [OfflineSourceMetadata] {
        return MyLibraryManager.shared.library.offlinePlayedByArtist(artist)
    }
}
