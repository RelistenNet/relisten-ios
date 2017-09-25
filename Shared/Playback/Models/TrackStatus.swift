//
//  TrackStatus.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

public class TrackStatus {
    public let track: SourceTrack
    
    public var isPlaying: Bool {
        get {
            return PlaybackController.sharedInstance.player.isPlaying
        }
    }
    
    public var isActiveTrack: Bool {
        get {
            return PlaybackController.sharedInstance.player.currentItem?.playbackURL == track.mp3_url
        }
    }
    
    public init(forTrack: SourceTrack) {
        track = forTrack
    }
}
