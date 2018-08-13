//
//  LegacyPhishOfflineTrackImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class LegacyPhishOfflineTrackImporter {
    private let cacheSubDir = "phish.in"
    private lazy var cacheDir : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
            "/com.alecgorge.phish.cache" +
            "/" + self.cacheSubDir
    }()
    
    private let artistSlug = "phish"
    private let legacyMapper = LegacyMapper()
    private let fm = FileManager.default
    
    public init() { }
    
    public func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.backgroundImportLegacyOfflineTracks(completion: completion)
        }
    }
    
    private func backgroundImportLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
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
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Import complete")
            self.deleteDirectoryIfEmpty(self.cacheDir)
            completion(error)
        }
    }
    
    // MARK: Internals
    
    private func debug(_ str : String) {
        print("[Import] " + str)
    }
    
    private func legacyCacheDirectoryExists() -> Bool {
        var isDir : ObjCBool = false
        return (fm.fileExists(atPath: cacheDir, isDirectory: &isDir) && isDir.boolValue)
    }
    
    private func deleteDirectoryIfEmpty(_ path : String) {
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
            self.legacyMapper.loadShowInfoForDate(withArtistSlug: self.artistSlug, showDate: showDate) { (show) in
                if let show = show {
                    self.importOfflineTracks(forShow: show, artist: phishArtist)
                }
                group.leave()
            }
        }
    }
    
    private func allLegacyCachedShowDates() -> [String] {
        var retval : [String] = []
        
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
    
    private func fetchPhishArtist(completion : @escaping ((ArtistWithCounts?) -> Void)) {
        legacyMapper.fetchArtist(artistSlug, completion: completion)
    }
}
