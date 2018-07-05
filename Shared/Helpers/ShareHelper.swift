//
//  ShareHelper.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class ShareHelper {
    public static func url(forTrack track: Track) -> URL {
        let urlText = String(
            format: "https://relisten.live/%@/%@/%@/%@/%@?source=%d",
            track.showInfo.artist.slug,
            track.showInfo.show.yearFromDate,
            track.showInfo.show.monthFromDate,
            track.showInfo.show.dayFromDate,
            track.slug,
            track.showInfo.source.id
        )
        
        return URL(string: urlText)!
    }
    
    public static func url(forSource info: CompleteShowInformation) -> URL {
        let urlText = String(
            format: "https://relisten.live/%@/%@/%@/%@?source=%d",
            info.artist.slug,
            info.show.yearFromDate,
            info.show.monthFromDate,
            info.show.dayFromDate,
            info.source.id
        )
        
        return URL(string: urlText)!
    }
    
    public static func text(forTrack track: Track) -> String {
        let item = SourceTrackAudioItem(track)
        
        var text = item.displayText
        
        if track.showInfo.artist.features.track_durations, let dur = track.duration {
            text += " (\(dur.humanize()))"
        }
        
        text += " • " + item.displaySubtext

        return text
    }
    
    public static func text(forSource info: CompleteShowInformation) -> String {
        var text = String(format: "%@ • %@", info.artist.name, info.show.display_date)
        
        if info.artist.features.track_durations, let dur = info.source.duration {
            text += " (\(dur.humanize()))"
        }
        
        if let v = info.show.correctVenue(withFallback: info.source.venue) {
            text += " • \(v.name), \(v.location)"
        }

        return text
    }
}
