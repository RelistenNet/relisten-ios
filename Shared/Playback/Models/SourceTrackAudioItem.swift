//
//  SourceTrackAudioItem.swift
//  Relisten
//
//  Created by Alec Gorge on 7/4/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import AGAudioPlayer
import SINQ

public class SourceTrackAudioItem : AGAudioItem {
    public required init(_ track: SourceTrack, inSource: SourceFull, fromShow: Show, byArtist: SlimArtistWithFeatures) {
        super.init()
        
        self.displayText = track.title
        self.title = track.title
        
        var venueStr = ""
        
        if let v = fromShow.correctVenue(withFallback: inSource.venue) {
            venueStr = " — \(v.name), \(v.location)"
        }
        
        self.displaySubtext = "\(byArtist.name) — \(inSource.display_date)\(venueStr)"
        self.playbackURL = track.mp3_url
        self.metadataLoaded = true
    }
    
    public override func loadMetadata(_ metadataCallback: @escaping (AGAudioItem) -> Void) {
        metadataCallback(self)
    }
}

extension Show {
    public func correctVenue(withFallback: Venue?) -> Venue? {
        if let v = self.venue {
            return v
        }
        
        return withFallback
    }
}

extension SourceFull {
    public func toAudioItems(inShow: Show, byArtist: SlimArtistWithFeatures) -> [AGAudioItem] {
        var items: [AGAudioItem] = []
        
        for set in self.sets {
            for track in set.tracks {
                items.append(SourceTrackAudioItem(track, inSource: self, fromShow: inShow, byArtist: byArtist))
            }
        }
        
        return items
    }
}
