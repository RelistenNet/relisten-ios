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
import Observable

/// This is used for information that doens't come from Relisten.
/// It is like a "sidecar" set of data that provides device-specific info
public class OfflineTrackMetadata : Codable {
    public let fileSize: UInt64
    
    public init(fileSize: UInt64) {
        self.fileSize = fileSize
    }
}

public struct OfflineSourceMetadata : Codable, Hashable {
    public var hashValue: Int {
        return completeShowInformation.hashValue
    }

    public static func == (lhs: OfflineSourceMetadata, rhs: OfflineSourceMetadata) -> Bool {
        return lhs.completeShowInformation == rhs.completeShowInformation
    }
    
    public var year: String {
        let yearEnd = completeShowInformation.show.display_date.index(completeShowInformation.show.display_date.startIndex, offsetBy: 4)
        return String(completeShowInformation.show.display_date[..<yearEnd])
    }
    
    public var show: Show {
        return completeShowInformation.show
    }
    
    public var source: SourceFull {
        return completeShowInformation.source
    }
    
    public var artist: ArtistWithCounts {
        return completeShowInformation.artist
    }
    
    public let completeShowInformation: CompleteShowInformation
    
    public let dateAdded: Date
    
    public static func from(track: Track) -> OfflineSourceMetadata {
        return self.init(completeShowInformation: track.showInfo, dateAdded: Date())
    }
    
    private enum CodingKeys: String, CodingKey {
        case completeShowInformation
        case dateAdded
    }
}

public class MyLibrary {
    public var shows: [CompleteShowInformation] = []
    public var artistIds: Set<Int> = []
    public lazy var artistIdsChanged = Observable(artistIds)
    
    public static let MaxRecentlyPlayedShows: Int = 25
    public var recentlyPlayedTracks: [Track] = []
    
    public var offlineTrackURLs: Set<URL> = []
    public var downloadBacklog: [Track] = []
    public var offlineSourcesMetadata: Set<OfflineSourceMetadata> = []
    
    public lazy var observeOfflineSources = Observable(offlineSourcesMetadata)
    
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
        shows = try json["shows"].arrayValue.map(CompleteShowInformation.init)
        artistIds = Set(json["artistIds"].arrayValue.map({ $0.intValue }))
        recentlyPlayedTracks = try json["recentlyPlayedTracks"].arrayValue.map(Track.init)

        try loadOfflineData()
        
        artistIdsChanged.value = artistIds
    }
    
    public func ToJSON() -> SwJSON {
        var s = SwJSON()
        s["shows"] = SwJSON(shows.map({ $0.originalJSON }))
        s["artistIds"] = SwJSON(Array(artistIds))
        s["recentlyPlayedTracks"] = SwJSON(recentlyPlayedTracks.map({ $0.originalJSON }))

        return s
    }
    
    public func URLNotAvailableOffline(_ track: Track, save: Bool = true) {
        let url = track.mp3_url
        
        offlineTrackURLs.remove(url)
        offlineTrackFileSizeCache.async.removeObject(forKey: url.absoluteString, completion: { _ in })
        
        offlineSourcesMetadata.remove(OfflineSourceMetadata.from(track: track))
        
        if save {
            saveOfflineTrackUrls()
            saveOfflineSourcesMetadata()
            
            observeOfflineSources.value = offlineSourcesMetadata
        }
    }
    
    public func isShowInLibrary(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return shows.contains(where: { $0.show.display_date == show.display_date && $0.artist.id == byArtist.id })
    }
    
    public func queueToBacklog(_ track: Track) {
        downloadBacklog.append(track)
        
        saveDownloadBacklog()
    }
    
    public func dequeueFromBacklog() -> Track? {
        if downloadBacklog.count == 0 {
            return nil
        }
        
        let first = downloadBacklog.removeFirst()
        
        saveDownloadBacklog()
        
        return first
    }
}

extension MyLibrary : RelistenDownloadManagerDelegate {
    public func trackBecameAvailableOffline(_ track: Track) {
        if offlineTrackURLs.insert(track.mp3_url).inserted {
            saveOfflineTrackUrls()
        }

        if offlineSourcesMetadata.insert(OfflineSourceMetadata.from(track: track)).inserted {
            saveOfflineSourcesMetadata()
            
            observeOfflineSources.value = offlineSourcesMetadata
        }
    }
    
    func trackSizeBecameKnown(trackURL : URL, fileSize: UInt64) {
        do {
            try offlineTrackFileSizeCache.setObject(OfflineTrackMetadata(fileSize: fileSize), forKey: trackURL.absoluteString)
        }
        catch {
            print(error)
            RelistenNotificationBar.display(withMessage: error.localizedDescription, forDuration: 10)
        }
    }
    
    public func trackSizeBecameKnown(_ track: Track, fileSize: UInt64) {
        trackSizeBecameKnown(trackURL: track.mp3_url, fileSize: fileSize)
    }
    
    public func trackSizeBecameKnown(_ sourceTrack: SourceTrack, fileSize: UInt64) {
        trackSizeBecameKnown(trackURL: sourceTrack.mp3_url, fileSize: fileSize)
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
            downloadBacklog = try offlineCache.object(ofType: [Track].self, forKey: "downloadBacklog")
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
    public func isTrackAvailableOffline(_ track: Track) -> Bool {
        return offlineTrackURLs.contains(track.mp3_url)
    }
    
    public func isTrackAvailableOffline(_ track: SourceTrack) -> Bool {
        return offlineTrackURLs.contains(track.mp3_url)
    }
    
    public func isSourceFullyAvailableOffline(_ source: SourceFull) -> Bool {
        if sinq(source.tracksFlattened).any({ !isTrackAvailableOffline($0) }) {
            return false
        }
        
        return true
    }
    
    public func isArtistAtLeastPartiallyAvailableOffline(_ artist: SlimArtist) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.artist.id == artist.id })
    }
    
    public func isShowAtLeastPartiallyAvailableOffline(_ show: Show) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.show.id == show.id })
    }
    
    public func isSourceAtLeastPartiallyAvailableOffline(_ source: SourceFull) -> Bool {
        return sinq(source.tracksFlattened).any({ isTrackAvailableOffline($0) })
    }
    
    public func isYearAtLeastPartiallyAvailableOffline(_ year: Year) -> Bool {
        return sinq(offlineSourcesMetadata).any({ $0.year == year.year })
    }
}

extension MyLibrary {
    public func recentlyPlayedByArtist(_ artist: SlimArtist) -> [Track] {
        return recentlyPlayedTracks.filter({ $0.showInfo.artist == artist })
    }
    
    public func offlinePlayedByArtist(_ artist: SlimArtist) -> [OfflineSourceMetadata] {
        return offlineSourcesMetadata
            .filter({ $0.artist == artist })
            .sorted(by: { $0.show.date < $1.show.date })
    }
    
    public func favoritedShowsPlayedByArtist(_ artist: SlimArtist) -> [CompleteShowInformation] {
        return shows
            .filter({ $0.artist == artist })
            .sorted(by: { $0.show.date < $1.show.date })
    }
}

extension MyLibrary {
    public func trackWasPlayed(_ track: Track) -> Bool {
        for (idx, complete) in recentlyPlayedTracks.enumerated() {
            if complete.showInfo.show == track.showInfo.show && complete.showInfo.artist == track.showInfo.artist {
                // move that show to the front
                recentlyPlayedTracks.remove(at: idx)
                recentlyPlayedTracks.insertAtBeginning(track, ensuringMaxCapacity: MyLibrary.MaxRecentlyPlayedShows)
                
                return true
            }
        }
        
        recentlyPlayedTracks.insertAtBeginning(track, ensuringMaxCapacity: MyLibrary.MaxRecentlyPlayedShows)
        
        return true
    }
}
