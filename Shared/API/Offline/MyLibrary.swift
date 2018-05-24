//
//  MyLibrary.swift
//  Relisten
//
//  Created by Alec Gorge on 5/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON
import Cache
import Async
import SINQ

public class ShowWithSourcesArtistContainer {
    public let show: ShowWithSources
    public let artist: SlimArtistWithFeatures
    
    public init(show: ShowWithSources, byArtist: SlimArtistWithFeatures) {
        self.show = show
        self.artist = byArtist
    }
    
    public init(json: SwJSON) throws {
        show = try ShowWithSources(json: json["show"])
        artist = try SlimArtistWithFeatures(json: json["artist"])
    }
    
    public var originalJSON: SwJSON {
        get {
            var s = SwJSON()
            s["show"] = show.originalJSON
            s["artist"] = artist.originalJSON
            return s
        }
    }
}

/// This is used for information that doens't come from Relisten.
/// It is like a "sidecar" set of data that provides device-specific info
public class OfflineTrackMetadata : Codable {
    public typealias CacheType = OfflineTrackMetadata
    
    public let fileSize: UInt64
    
    public init(fileSize: UInt64) {
        self.fileSize = fileSize
    }
}

public class MyLibrary {
    public var shows: [ShowWithSourcesArtistContainer]
    public var artistIds: Set<Int>
    
    public var offlineTrackURLs: Set<URL>
    public var downloadBacklog: [SourceTrack]
    
    private static let offlineTrackFileSizeCacheName = "offlineTrackSize"
    private static let offlineCacheName = "offline"
    
    public let offlineCache = try! Storage(
        diskConfig: DiskConfig(
            name: MyLibrary.offlineCacheName,
            expiry: .never,
            maxSize: 1024 * 1024 * 250,
            directory: PersistentCacheDirectory
        )
    )
    
    public let offlineTrackFileSizeCache = try! Storage(
        diskConfig: DiskConfig(
            name: MyLibrary.offlineTrackFileSizeCacheName,
            expiry: .never,
            maxSize: 0,
            directory: nil,
            protectionType: nil
        ),
        memoryConfig: MemoryConfig(
            expiry: .never,
            countLimit: 4000,
            totalCostLimit: 1024 * 1024 * 16
        )
    )
    
    public init() {
        shows = []
        artistIds = []
        offlineTrackURLs = []
        downloadBacklog = []
        
        try! loadOfflineData()
    }
    
    public init(json: SwJSON) throws {
        shows = try json["shows"].arrayValue.map(ShowWithSourcesArtistContainer.init)
        artistIds = Set(json["artistIds"].arrayValue.map({ $0.intValue }))
        offlineTrackURLs = []
        downloadBacklog = []
        
        try loadOfflineData()
    }
    
    public func ToJSON() -> SwJSON {
        var s = SwJSON()
        s["shows"] = SwJSON(shows.map({ $0.originalJSON }))
        s["artistIds"] = SwJSON(Array(artistIds))
        
        return s
    }
    
    public func URLIsAvailableOffline(_ url: URL) {
        offlineTrackURLs.insert(url)
        
        saveOfflineTrackUrls()
    }
    
    public func URLNotAvailableOffline(_ url: URL, save: Bool = true) {
        offlineTrackURLs.remove(url)
        offlineTrackFileSizeCache.async.removeObject(forKey: url.absoluteString, completion: { _ in })
        
        if save {
            saveOfflineTrackUrls()
        }
    }
    
    public func loadOfflineData() throws {
        do {
            offlineTrackURLs = try offlineCache.object(ofType: Set<URL>.self, forKey: "offlineTrackURLs")
        }
        catch CocoaError.fileReadNoSuchFile {
            offlineTrackURLs = Set<URL>()
        }
        
        do {
            downloadBacklog = try offlineCache.object(ofType: [SourceTrack].self, forKey: "downloadBacklog")
        }
        catch CocoaError.fileReadNoSuchFile {
            downloadBacklog = []
        }
    }
    
    public func saveOfflineData() {
        saveOfflineTrackUrls()
        saveDownloadBacklog()
    }
    
    public func saveOfflineTrackUrls() {
        offlineCache.async.setObject(offlineTrackURLs, forKey: "offlineTrackURLs", completion: { _ in })
    }
    
    public func saveDownloadBacklog() {
        offlineCache.async.setObject(downloadBacklog, forKey: "downloadBacklog", completion: { _ in })
    }
    
    public func isShowInLibrary(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return shows.contains(where: { $0.show.display_date == show.display_date && $0.artist.id == byArtist.id })
    }
    
    public func isTrackAvailableOffline(track: SourceTrack) -> Bool {
        return offlineTrackURLs.contains(track.mp3_url)
    }
    
    public func isSourceFullyAvailableOffline(source: SourceFull) -> Bool {
        for track in source.tracksFlattened {
            if !isTrackAvailableOffline(track: track) {
                return false
            }
        }
        
        return true
    }
    
    public func queueToBacklog(_ track: SourceTrack) {
        downloadBacklog.append(track)
        
        saveDownloadBacklog()
    }
    
    public func dequeueFromBacklog() -> SourceTrack? {
        if downloadBacklog.count == 0 {
            return nil
        }
        
        let first = downloadBacklog.removeFirst()
        
        saveDownloadBacklog()
        
        return first
    }
}

extension MyLibrary : RelistenDownloadManagerDelegate {
    public func urlBecameAvailableOffline(url: URL) {
        URLIsAvailableOffline(url)
    }
    
    public func urlSizeBecameKnown(url: URL, fileSize: UInt64) {
        do {
            try offlineTrackFileSizeCache.setObject(OfflineTrackMetadata(fileSize: fileSize), forKey: url.absoluteString)
        }
        catch {
            print(error)
            RelistenNotificationBar.display(withMessage: error.localizedDescription, forDuration: 10)
        }
    }
}
