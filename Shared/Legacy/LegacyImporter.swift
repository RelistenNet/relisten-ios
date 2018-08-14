//
//  LegacyImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/14/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import SDCloudUserDefaults

public class LegacyImporter {
    var cacheSubDir : String
    
    lazy var cachePath : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
            "/com.alecgorge.phish.cache" +
            "/" + self.cacheSubDir
    }()
    lazy var persistedObjectsPath : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
        "/persisted_objects"
    }()
    
    let favoritesKey = "favorites"
    let legacyMapper = LegacyMapper()
    let fm = FileManager.default
    
    public init() {
        SDCloudUserDefaults.registerForNotifications()
        cacheSubDir = ""
    }
    
    public func performLegacyImport(completion: @escaping (Error?) -> Void) {
        var error : Error? = nil
        let group : DispatchGroup = DispatchGroup()
        
        group.enter()
        DispatchQueue.global(qos: .background).async {
            self.importLegacyOfflineTracks(completion: { blockError in
                if blockError != nil {
                    error = blockError
                }
                group.leave()
            })
        }
        
        group.enter()
        DispatchQueue.global(qos: .background).async {
            self.importLegacyFavoriteShows(completion: { blockError in
                if blockError != nil {
                    error = blockError
                }
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("PhishOD legacy import complete")
            self.cleanupLegacyFiles()
            completion(error)
        }
    }

    func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        fatalError("Must be implemented by subclass")
    }
    
    func importLegacyFavoriteShows(completion: @escaping (Error?) -> Void) {
        fatalError("Must be implemented by subclass")
    }
    
    func importLegacyFavoriteShowsForArtist(_ artistSlug : String, completion: @escaping (Error?) -> Void) {
        var error : Error? = nil
        let group = DispatchGroup()
        
        if let favoritesDict = SDCloudUserDefaults.object(forKey: favoritesKey) as? [String : [String]] {
            if let shows = favoritesDict[artistSlug] {
                for show in shows {
                    group.enter()
                    self.legacyMapper.getCompleteShowForDate(show, artist: artistSlug) { (showInfo, blockError) in
                        if let showInfo = showInfo {
                            self.debug("Favoriting show \(show) by \(artistSlug)")
                            MyLibrary.shared.favoriteSource(show: showInfo)
                        } else {
                            if blockError != nil {
                                error = blockError
                            } else {
                                error = LegacyMapper.GenericImportError()
                            }
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Import for artist \(artistSlug) is complete")
            if error == nil {
                if let favoritesDict = SDCloudUserDefaults.object(forKey: self.favoritesKey) as? [String : [String]] {
                    var favorites = favoritesDict
                    favorites[artistSlug] = nil
                    SDCloudUserDefaults.setObject(favorites, forKey: self.favoritesKey)
                }
            }
            completion(error)
        }
    }
    
    private func cleanupLegacyFiles() {
        do {
            try fm.removeItem(atPath: persistedObjectsPath)
        } catch { }
    }

    // MARK: Helpers
    func debug(_ str : String) {
        print("[Import] " + str)
    }
    
    func legacyCachePathExists() -> Bool {
        var isDir : ObjCBool = false
        return (fm.fileExists(atPath: cachePath, isDirectory: &isDir) && isDir.boolValue)
    }
    
    func deleteDirectoryIfEmpty(_ path : String) {
        do {
            if try fm.contentsOfDirectory(atPath: path).count == 0 {
                try fm.removeItem(atPath: path)
            }
        } catch {
            debug("Error while removing show directory at \(path): \(error)")
        }
    }
    
    func allSubdirsAtPath(_ path : String) -> [String] {
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
}
