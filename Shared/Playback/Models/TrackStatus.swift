//
//  TrackStatus.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

public class TrackStatus : Codable {
    public let track: SourceTrack
    
    public var isPlaying: Bool {
        get {
            return (PlaybackController.sharedInstance.player.isPlaying && self.isActiveTrack)
        }
    }
    
    public var isActiveTrack: Bool {
        get {
            if let relisten = (PlaybackController.sharedInstance.player.currentItem as? SourceTrackAudioItem)?.relisten {
                return relisten.track.track.mp3_url == track.mp3_url
            }
            return false
        }
    }
    
    public var isActivelyDownloading: Bool {
        return RelistenDownloadManager.shared.isTrackActivelyDownloading(track)
    }
    
    public var isQueuedToDownload: Bool {
        return RelistenDownloadManager.shared.isTrackQueuedToDownload(track)
    }
    
    public var isAvailableOffline: Bool {
        return MyLibraryManager.shared.library.isTrackAvailableOffline(track: track)
    }
    
    public init(forTrack: SourceTrack) {
        track = forTrack
    }
}
