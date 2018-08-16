//
//  LegacyRelistenImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta
import SDCloudUserDefaults
import SwiftyJSON

public class LegacyRelistenImporter : LegacyImporter {
    override public init() {
        super.init()
        cacheSubDir = "relisten.net"
    }
    
    override func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        var error : Error? = nil
        let group = DispatchGroup()
        if (legacyCachePathExists()) {
            debug("Starting import of legacy offline Relisten tracks")
            for artistSlug in allSubdirsAtPath(cachePath) {
                let artistPath = cachePath + "/" + artistSlug
                for showIDString in allSubdirsAtPath(artistPath) {
                    let showPath = artistPath + "/" + showIDString
                    if let showID = Int(showIDString) {
                        group.enter()
                        importLegacyOfflineShow(withID: showID, artistSlug: artistSlug) { (blockError) in
                            if blockError != nil {
                                error = blockError
                            } else {
                                self.deleteDirectoryIfEmpty(showPath)
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Import complete")
            for artistSlug in self.allSubdirsAtPath(self.cachePath) {
                let artistPath = self.cachePath + "/" + artistSlug
                self.deleteDirectoryIfEmpty(artistPath)
            }
            self.deleteDirectoryIfEmpty(self.cachePath)
            
            completion(error)
        }
    }
    
    override func importLegacyFavoriteShows(completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var error : Error? = nil
        
        if let favoritesDict = SDCloudUserDefaults.object(forKey: favoritesKey) as? [String : [String]] {
            for (artist, _) in favoritesDict {
                group.enter()
                self.importLegacyFavoriteShowsForArtist(artist) { (blockError) in
                    if blockError != nil {
                        error = blockError
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Favorites import complete")
            completion(error)
        }
    }
    
    // MARK: Internals
    private func importLegacyOfflineShow(withID showID : Int, artistSlug : String, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var error : Error? = nil
        
        let showPath = cachePath + "/" + artistSlug + "/" + String(showID)
        do {
            debug("Processing show at \(showPath)...")
            
            for trackString in try fm.contentsOfDirectory(atPath: showPath) {
                let trackPath = showPath + "/" + trackString
                if let trackIDString = trackString.split(separator: ".").map(String.init).first, let trackID = Int(trackIDString) {
                    group.enter()
                    debug("Importing track \(trackID) for show \(showID)")
                    legacyMapper.matchLegacyTrack(trackID, artist: artistSlug, showID: showID) { (track, blockError) in
                        if let track = track {
                            self.handleImportOfTrack(atPath: trackPath, track: track) { (blockError) in
                                if blockError != nil {
                                    error = blockError
                                }
                                group.leave()
                            }
                        } else {
                            if blockError != nil {
                                error = blockError
                            }
                            group.leave()
                        }
                    }
                }
            }
        } catch let blockError {
            error = blockError
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.deleteDirectoryIfEmpty(showPath)
            completion(error)
        }
    }
    
    private func handleImportOfTrack(atPath filePath : String, track : Track, completion: @escaping (Error?) -> Void) {
        DownloadManager.shared.importDownloadedTrack(track, filePath: filePath)
        
        do {
            try fm.removeItem(atPath: filePath)
        } catch {
            // This isn't necessarily an error since the DownloadManager should have performed a move of the file
        }
        
        completion(nil)
    }
}
