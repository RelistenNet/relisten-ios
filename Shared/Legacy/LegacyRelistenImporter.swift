//
//  LegacyRelistenImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta

public class LegacyRelistenImporter {
    private let cacheSubDir = "relisten.net"
    private lazy var cachePath : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
            "/com.alecgorge.phish.cache" +
            "/" + self.cacheSubDir
    }()
    private lazy var persistedObjectsPath : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
        "/persisted_objects"
    }()
    
    private let legacyMapper = LegacyMapper()
    private let fm = FileManager.default
    
    public init() { }
    
    public func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.backgroundImportLegacyOfflineTracks(completion: completion)
        }
    }
    
    public func cleanupLegacyFiles() {
        do {
            try fm.removeItem(atPath: persistedObjectsPath)
        } catch { }
    }

    public func backgroundImportLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
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
                    legacyMapper.matchLegacyTrack(artist: artistSlug, showID: showID, trackID: trackID) { (track, blockError) in
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
    
    // MARK: Filesystem helpers
    private func legacyCachePathExists() -> Bool {
        var isDir : ObjCBool = false
        return (fm.fileExists(atPath: cachePath, isDirectory: &isDir) && isDir.boolValue)
    }
    
    private func deleteDirectoryIfEmpty(_ path : String) {
        do {
            var filesFound = false
            for file in try fm.contentsOfDirectory(atPath: path) {
                if !file.hasPrefix(".") {
                    filesFound = true
                    break
                }
            }
            if !filesFound {
                try fm.removeItem(atPath: path)
            }
        } catch {
            debug("Error while removing show directory at \(path): \(error)")
        }
    }
    
    private func allSubdirsAtPath(_ path : String) -> [String] {
        var retval : [String] = []
        
        do {
            for subdirectory in try fm.contentsOfDirectory(atPath: path) {
                var isDir : ObjCBool = false
                if fm.fileExists(atPath: path + "/" + subdirectory, isDirectory: &isDir), isDir.boolValue {
                    retval.append(subdirectory)
                }
            }
        } catch let error {
            debug("Exception while getting subdirectories at \(path): \(error)")
        }
        
        return retval
    }
    
    // MARK: Debugging
    private func debug(_ str : String) {
        print("[Import] " + str)
    }
    

}
