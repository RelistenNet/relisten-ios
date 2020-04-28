//
//  LegacyPhishODImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class LegacyPhishODImporter : LegacyImporter {
    private let artistSlug = "phish"
    
    override public init() {
        super.init()
        cacheSubDir = "phish.in"
    }
    
    override func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        let error : Error? = nil
        let group = DispatchGroup()
        if (legacyCachePathExists()) {
            debug("Starting import of legacy offline Phish tracks")
            group.enter()
            self.fetchPhishArtist { (phishArtist) in
                if let phishArtist = phishArtist {
                    self.continueImportLegacyOfflineTracks(phishArtist: phishArtist, group: group)
                } else {
                    self.warning("Abandoning import because we couldn't fetch the artist object for Phish")
                    // (farkas) TODO: Error handling 🙃
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Download import complete")
            self.deleteDirectoryIfEmpty(self.cachePath)
            completion(error)
        }
    }
    
    override func importLegacyFavoriteShows(completion: @escaping (Error?) -> Void) {
        self.importLegacyFavoriteShowsForArtist("phish", completion: completion)
    }
    
    // MARK: Internals
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
            if legacyCachePathExists() {
                for showDirectory in try fm.contentsOfDirectory(atPath: self.cachePath) {
                    var isDir : ObjCBool = false
                    if fm.fileExists(atPath: cachePath + "/" + showDirectory, isDirectory: &isDir), isDir.boolValue {
                        retval.append(showDirectory)
                    }
                }
            }
        } catch let error as NSError {
            debug("Exception while searching for shows at \(cachePath): \(error)")
        }
        
        return retval
    }
    
    private func importOfflineTracks(forShow show : ShowWithSources, artist: ArtistWithCounts) {
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
            let showDir = cachePath + "/" + show.display_date
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
            debug("[Import] Error while searching for shows at \(cachePath): \(error)")
        }
    }
    
    private func fetchPhishArtist(completion : @escaping ((ArtistWithCounts?) -> Void)) {
        legacyMapper.fetchArtist(artistSlug, completion: completion)
    }
}
