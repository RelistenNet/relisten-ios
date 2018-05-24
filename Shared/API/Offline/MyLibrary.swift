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
    public let fileSize: UInt64
    
    public init(fileSize: UInt64) {
        self.fileSize = fileSize
    }
}

public struct OfflineSourceMetadata : Codable, Hashable {
    public let artistId: Int
    
    public let year: String
    public let showDisplayDate: String
    
    public let showId: Int
    public let sourceId: Int
    
    public static func from(completeTrack track: CompleteTrackShowInformation) -> OfflineSourceMetadata {
        let yearEnd = track.show.display_date.index(track.show.display_date.startIndex, offsetBy: 4)
        let year = String(track.show.display_date[..<yearEnd])
        
        return self.init(artistId: track.artist.id, year: year, showDisplayDate: track.show.display_date, showId: track.show.id, sourceId: track.source.id)
    }
}

public class MyLibrary {
    public var shows: [ShowWithSourcesArtistContainer] = []
    public var artistIds: Set<Int> = []
    
    public var offlineTrackURLs: Set<URL> = []
    public var downloadBacklog: [CompleteTrackShowInformation] = []
    public var offlineSourcesMetadata: Set<OfflineSourceMetadata> = []
    
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
        try! loadOfflineData()
    }
    
    public init(json: SwJSON) throws {
        shows = try json["shows"].arrayValue.map(ShowWithSourcesArtistContainer.init)
        artistIds = Set(json["artistIds"].arrayValue.map({ $0.intValue }))

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
    
    public func URLNotAvailableOffline(_ track: CompleteTrackShowInformation, save: Bool = true) {
        let url = track.track.track.mp3_url
        
        offlineTrackURLs.remove(url)
        offlineTrackFileSizeCache.async.removeObject(forKey: url.absoluteString, completion: { _ in })
        
        offlineSourcesMetadata.remove(OfflineSourceMetadata.from(completeTrack: track))
        
        if save {
            saveOfflineTrackUrls()
            saveOfflineSourcesMetadata()
        }
    }
    
    public func isShowInLibrary(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return shows.contains(where: { $0.show.display_date == show.display_date && $0.artist.id == byArtist.id })
    }
    
    public func queueToBacklog(_ track: CompleteTrackShowInformation) {
        downloadBacklog.append(track)
        
        saveDownloadBacklog()
    }
    
    public func dequeueFromBacklog() -> CompleteTrackShowInformation? {
        if downloadBacklog.count == 0 {
            return nil
        }
        
        let first = downloadBacklog.removeFirst()
        
        saveDownloadBacklog()
        
        return first
    }
}

extension MyLibrary : RelistenDownloadManagerDelegate {
    public func trackBecameAvailableOffline(_ track: CompleteTrackShowInformation) {
        URLIsAvailableOffline(track.track.track.mp3_url)
        
        offlineSourcesMetadata.insert(OfflineSourceMetadata.from(completeTrack: track))
        
        saveOfflineSourcesMetadata()
    }
    
    public func trackSizeBecameKnown(_ track: CompleteTrackShowInformation, fileSize: UInt64) {
        do {
            try offlineTrackFileSizeCache.setObject(OfflineTrackMetadata(fileSize: fileSize), forKey: track.track.track.mp3_url.absoluteString)
        }
        catch {
            print(error)
            RelistenNotificationBar.display(withMessage: error.localizedDescription, forDuration: 10)
        }
    }
}

/// boring loading and saving
extension MyLibrary {
    public func loadOfflineData() throws {
        do {
            offlineTrackURLs = try offlineCache.object(ofType: Set<URL>.self, forKey: "offlineTrackURLs")
        }
        catch CocoaError.fileReadNoSuchFile {
            offlineTrackURLs = Set<URL>()
        }
        
        do {
            downloadBacklog = try offlineCache.object(ofType: [CompleteTrackShowInformation].self, forKey: "downloadBacklog")
        }
        catch CocoaError.fileReadNoSuchFile {
            downloadBacklog = []
        }
        
        do {
            offlineSourcesMetadata = try offlineCache.object(ofType: Set<OfflineSourceMetadata>.self, forKey: "offlineSourcesMetadata")
        }
        catch CocoaError.fileReadNoSuchFile {
            offlineSourcesMetadata = []
        }
    }
    
    public func saveOfflineData() {
        saveOfflineTrackUrls()
        saveDownloadBacklog()
        saveOfflineSourcesMetadata()
    }
    
    public func saveOfflineTrackUrls() {
        offlineCache.async.setObject(offlineTrackURLs, forKey: "offlineTrackURLs", completion: { _ in })
    }
    
    public func saveDownloadBacklog() {
        offlineCache.async.setObject(downloadBacklog, forKey: "downloadBacklog", completion: { _ in })
    }
    
    public func saveOfflineSourcesMetadata() {
        offlineCache.async.setObject(offlineSourcesMetadata, forKey: "offlineSourcesMetadata", completion: { _ in })
    }
}

/// offline checks
extension MyLibrary {
    public func isTrackAvailableOffline(track: SourceTrack) -> Bool {
        return offlineTrackURLs.contains(track.mp3_url)
    }
    
    public func isSourceFullyAvailableOffline(source: SourceFull) -> Bool {
        if sinq(source.tracksFlattened).any({ !isTrackAvailableOffline(track: $0) }) {
            return false
        }
        
        return true
    }
    
    public func isArtistAtLeastPartiallyAvailableOffline(_ artist: SlimArtist) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.artistId == artist.id })
    }
    
    public func isShowAtLeastPartiallyAvailableOffline(_ show: Show) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.showId == show.id })
    }
    
    public func isSourceAtLeastPartiallyAvailableOffline(_ source: SourceFull) -> Bool {
        return sinq(source.tracksFlattened).any({ isTrackAvailableOffline(track: $0) })
    }
    
    public func isYearAtLeastPartiallyAvailableOffline(_ year: Year) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.year == year.year })
    }
}
