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
    public let track: Track
    
    public required init(_ track: Track) {
        self.track = track

        super.init()
        
        self.title = track.title
        self.artist = track.showInfo.artist.name
        
        if let d = track.duration {
            self.duration = d
        }
        
        self.trackNumber = track.track_position
        
        var venueStr = ""
        
        if let v = track.showInfo.show.correctVenue(withFallback: track.showInfo.source.venue) {
            venueStr = " • \(v.name), \(v.location)"
        }
        
        self.album = "\(track.showInfo.source.display_date)\(venueStr)"
        
        self.displayText = track.title
        self.displaySubtext = "\(track.showInfo.artist.name) • \(album)"
        
        if let offlineURL = RelistenDownloadManager.shared.offlineURL(forTrack: track) {
            self.playbackURL = offlineURL
        }
        else {
            self.playbackURL = track.mp3_url
        }
        
        AlbumArtImageCache.shared.cache.retrieveImage(for: track.showInfo.show.fastImageCacheWrapper(), withFormatName: AlbumArtImageCache.imageFormatMedium) { [weak self] (_, _, i) in
            guard let s = self else { return }
            guard let image = i else { return }
            s.albumArt = image
        }

        self.metadataLoaded = true
    }
    
    public override func loadMetadata(_ metadataCallback: @escaping (AGAudioItem) -> Void) {
        metadataCallback(self)
    }
}

extension AGAudioPlayerUpNextQueue {
    public func findSourceTrackAudioItem(forTrack track: Track) -> SourceTrackAudioItem? {
        for item in queue {
            if let st = item as? SourceTrackAudioItem {
                if st.track == track {
                    return st
                }
            }
        }
        
        return nil
    }
}

extension Show {
    public func correctVenue(withFallback: VenueWithShowCount?) -> VenueWithShowCount? {
        if let v = self.venue {
            return v
        }
        
        return withFallback
    }
}

extension SourceFull {
    public func toAudioItems(inShow: Show, byArtist: ArtistWithCounts) -> [AGAudioItem] {
        var items: [AGAudioItem] = []
        
        let showInfo : CompleteShowInformation = CompleteShowInformation(source: self, show: inShow, artist: byArtist)
        
        for set in self.sets {
            for sourceTrack in set.tracks {
                let track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
                items.append(track.toAudioItem())
            }
        }
        
        return items
    }
}

extension Track {
    public func toAudioItem() -> AGAudioItem {
        return SourceTrackAudioItem(self)
    }
}
