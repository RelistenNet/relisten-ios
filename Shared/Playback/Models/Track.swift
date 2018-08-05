//
//  Track.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

public class Track : Codable, Hashable {
    public enum PlaybackState : String, Codable {
        case notActive
        case paused
        case playing
    }

    public enum DownloadState {
        case none
        case queued
        case downloading
        case downloaded
    }
    
    public let showInfo : CompleteShowInformation

    // Note: This should be a complete passthrough for SourceTrack so that the properties are visible on Track.
    // Resist the temptation to change the names or alter the SourceTrack properties in the getter
    public var id : Int { get { return sourceTrack.id } }
    public var uuid : UUID { get { return sourceTrack.uuid } }
    public var source_id : Int { get { return sourceTrack.source_id } }
    public var set_id : Int { get { return sourceTrack.source_set_id } }
    public var track_position : Int { get { return sourceTrack.track_position } }
    public var duration : TimeInterval? { get { return sourceTrack.duration } }
    public var title : String { get { return sourceTrack.title } }
    public var slug : String { get { return sourceTrack.slug } }
    public var mp3_url : URL { get { return sourceTrack.mp3_url } }
    public var md5 : String? { get { return sourceTrack.md5 } }
    
    public let sourceTrack: SourceTrack
    
    public var playbackState : PlaybackState {
        get {
            var isActiveTrack = false
            if let activeTrack = (PlaybackController.sharedInstance.player.currentItem as? SourceTrackAudioItem)?.track {
                isActiveTrack = (activeTrack.mp3_url == mp3_url)
            }
            if isActiveTrack {
                if PlaybackController.sharedInstance.player.isPlaying {
                    return .playing
                } else {
                    return .paused
                }
            }
            return .notActive
        }
    }
    
    
    public var downloadState : DownloadState {
        get {
            if RelistenDownloadManager.shared.isTrackActivelyDownloading(self) {
                return .downloading
            } else if RelistenDownloadManager.shared.isTrackQueuedToDownload(self) {
                return .queued
            } else if MyLibrary.shared.isTrackAvailableOffline(self) {
                return .downloaded
            }
            return .none
        }
    }
    
    public init(sourceTrack : SourceTrack, showInfo : CompleteShowInformation) {
        self.sourceTrack = sourceTrack
        self.showInfo = showInfo
    }
    
    public init(_ json: SwJSON) throws {
        sourceTrack = try SourceTrack(json: json["track"])
        
        let source = try SourceFull(json: json["source"])
        let sourceShow = try ShowWithSources(json: json["show"])
        let artist = try ArtistWithCounts(json: json["artist"])
        
        showInfo = CompleteShowInformation(source: source, show: sourceShow, artist: artist)
    }
    
    public var hashValue: Int {
        return mp3_url.hashValue ^ showInfo.hashValue
    }
    
    public static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    public func isEqual(_ other: Track) -> Bool {
        return showInfo.isEqual(other.showInfo) &&
               self.mp3_url == other.mp3_url
    }
    
    public var originalJSON: SwJSON {
        var j = SwJSON([:])
        
        j["track"] = sourceTrack.originalJSON
        j["source"] = showInfo.source.originalJSON
        j["show"] = showInfo.show.originalJSON
        j["artist"] = showInfo.artist.originalJSON
        
        return j
    }
}
