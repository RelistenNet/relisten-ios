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
    public let relisten: CompleteTrackShowInformation
    
    public required init(_ track: SourceTrack, inSource: SourceFull, fromShow: Show, byArtist: SlimArtistWithFeatures) {
        self.relisten = CompleteTrackShowInformation(track: TrackStatus(forTrack: track), source: inSource, show: fromShow, artist: byArtist)

        super.init()
        
        self.title = track.title
        self.artist = byArtist.name
        
        if let d = track.duration {
            self.duration = d
        }
        
        self.trackNumber = track.track_position
        
        var venueStr = ""
        
        if let v = fromShow.correctVenue(withFallback: inSource.venue) {
            venueStr = " — \(v.name), \(v.location)"
        }
        
        self.album = "\(inSource.display_date)\(venueStr)"
        
        self.displayText = track.title
        self.displaySubtext = "\(byArtist.name) — \(album)"
        
        if let offlineURL = RelistenDownloadManager.shared.offlineURL(forTrack: relisten) {
            self.playbackURL = offlineURL
        }
        else {
            self.playbackURL = track.mp3_url
        }

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
                items.append(track.toAudioItem(inSource: self, fromShow: inShow, byArtist: byArtist))
            }
        }
        
        return items
    }
}

extension SourceTrack {
    public func toAudioItem(inSource: SourceFull, fromShow: Show, byArtist: SlimArtistWithFeatures) -> AGAudioItem {
        return SourceTrackAudioItem(self, inSource: inSource, fromShow: fromShow, byArtist: byArtist)
    }
}
