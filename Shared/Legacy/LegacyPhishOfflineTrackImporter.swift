//
//  LegacyPhishOfflineTrackImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta

public class LegacyPhishOfflineTrackImporter {
    private lazy var cacheDir : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
            "/com.alecgorge.phish.cache" +
            "/phish.in"
    }()
    
    private let artistSlug = "phish"
    
    public init() { }
    
    public func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        let error : Error? = nil
        let group = DispatchGroup()
        if (legacyCacheDirectoryExists()) {
            debug("Starting import of legacy offline Phish tracks")
            group.enter()
            self.fetchPhishArtist { (phishArtist) in
                if let phishArtist = phishArtist {
                    self.continueImportLegacyOfflineTracks(phishArtist: phishArtist, group: group)
                } else {
                    self.debug("Abandoning import because we couldn't fetch the artist object for Phish")
                    // (farkas) TODO: Error handling 🙃
                }
                group.leave()
            }
        }
        
        deleteDirectoryIfEmpty(cacheDir)
        
        group.notify(queue: DispatchQueue.global()) {
            self.debug("Import complete")
            completion(error)
        }
    }
    
    // MARK: Internals
    
    private func debug(_ str : String) {
        print("[Import] " + str)
    }
    
    private func legacyCacheDirectoryExists() -> Bool {
        var isDir : ObjCBool = false
        return (FileManager.default.fileExists(atPath: cacheDir, isDirectory: &isDir) && isDir.boolValue)
    }
    
    private func deleteDirectoryIfEmpty(_ path : String) {
        let fm = FileManager.default
        do {
            if try fm.contentsOfDirectory(atPath: path).count == 0 {
                try fm.removeItem(atPath: path)
            }
        } catch {
            debug("Error while removing show directory at \(path): \(error)")
        }
    }
    
    private func continueImportLegacyOfflineTracks(phishArtist: ArtistWithCounts, group: DispatchGroup) {
        let showDates : [String] = allLegacyCachedShowDates()
        for showDate in showDates {
            group.enter()
            self.loadShowInfoForDate(showDate: showDate) { (show) in
                if let show = show {
                    self.importOfflineTracks(forShow: show, artist: phishArtist)
                }
                group.leave()
            }
        }
    }
    
    private func allLegacyCachedShowDates() -> [String] {
        var retval : [String] = []
        let fm = FileManager.default
        
        do {
            if legacyCacheDirectoryExists() {
                for showDirectory in try fm.contentsOfDirectory(atPath: self.cacheDir) {
                    var isDir : ObjCBool = false
                    if fm.fileExists(atPath: cacheDir + "/" + showDirectory, isDirectory: &isDir), isDir.boolValue {
                        retval.append(showDirectory)
                    }
                }
            }
        } catch let error as NSError {
            debug("Exception while searching for shows at \(cacheDir): \(error)")
        }
        
        return retval
    }
    
    private func importOfflineTracks(forShow show : ShowWithSources, artist: Artist) {
        var lastURLComponentsToTracks : [String : Track] = [:]
        for source in show.sources {
            let completeShowInfo = CompleteShowInformation(source: source, show: show, artist: artist)
            for sourceTrack in source.tracksFlattened {
                let lastURLComponent = sourceTrack.mp3_url.lastPathComponent
                let track = Track(sourceTrack: sourceTrack, showInfo: completeShowInfo)
                lastURLComponentsToTracks[lastURLComponent] = track
            }
        }
        
        do {
            let showDir = cacheDir + "/" + show.display_date
            let fm = FileManager.default
            var isDir : ObjCBool = false
            if fm.fileExists(atPath: showDir, isDirectory: &isDir), isDir.boolValue {
                debug("[Import] Processing show at \(showDir)...")
                
                for offlineFile in try fm.contentsOfDirectory(atPath: showDir) {
                    if let track = lastURLComponentsToTracks[offlineFile] {
                        let filePath = showDir + "/" + offlineFile
                        
                        DownloadManager.shared.importDownloadedTrack(track, filePath: filePath)
                        
                        // The download manager should have already moved the file, but just in case let's remove it here
                        do {
                            try fm.removeItem(atPath: filePath)
                        } catch { }
                    }
                }
                
                // Delete the show directory if it's empty now
                deleteDirectoryIfEmpty(showDir)

            }
        } catch let error as NSError {
            debug("[Import] Error while searching for shows at \(cacheDir): \(error)")
        }
    }
    
    // MARK: New API Helpers
    private func loadArtist(withSlug slug : String? = nil, completion : @escaping ((SlimArtistWithFeatures?) -> Void)) {
        RelistenApi.artist(withSlug: artistSlug).getLatestDataOrFetchIfNeeded { (latestData, _) in
            var artist : SlimArtistWithFeatures? = nil
            if let responseArtist : SlimArtistWithFeatures = latestData?.typedContent() {
                artist = responseArtist
            }
            completion(artist)
        }
    }
    
    private func loadShowInfoForDate(showDate : String, completion : @escaping ((ShowWithSources?) -> Void)) {
        loadArtist(withSlug: artistSlug) { (artist) in
            if let artist = artist {
                RelistenApi.show(onDate: showDate, byArtist: artist).getLatestDataOrFetchIfNeeded { (latestData, _) in
                    var show : ShowWithSources? = nil
                    if let responseShow : ShowWithSources = latestData?.typedContent() {
                        show = responseShow
                    }
                    completion(show)
                }
            }
        }
    }
    
    private var cachedPhishArtist : ArtistWithCounts? = nil
    private func fetchPhishArtist(completion : @escaping ((ArtistWithCounts?) -> Void)) {
        if cachedPhishArtist != nil {
            completion(cachedPhishArtist)
            return
        }
        
        RelistenApi.artists().getLatestDataOrFetchIfNeeded { (latestData, _) in
            if let artists : [ArtistWithCounts] = latestData?.typedContent() {
                for artist in artists {
                    if artist.slug == self.artistSlug {
                        self.cachedPhishArtist = artist
                    }
                }
            }
            completion(self.cachedPhishArtist)
        }
    }
}

extension Resource {
    func getLatestDataOrFetchIfNeeded(completion: @escaping (Entity<Any>?, Error?) -> Void) {
        if let latestData = self.latestData {
            completion(latestData, nil)
            return
        }
        
        if let request = self.loadFromCacheThenUpdate() {
            request.onCompletion { (responseInfo) in
                var latestData : Entity<Any>? = nil
                var error : RequestError? = nil
                switch responseInfo.response {
                case .success(let responseData):
                    latestData = responseData
                case .failure(let responseError):
                    error = responseError
                    break
                }
                completion(latestData, error)
            }
        } else {
            completion(nil, RequestError(userMessage: "Couldn't load siesta request", cause: RequestError.Cause.RequestLoadFailed()))
        }
    }
}

extension RequestError.Cause {
    public struct RequestLoadFailed : Error { }
}
