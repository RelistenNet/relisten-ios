//
//  LegacyImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/14/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import SDCloudUserDefaults
import SwiftyJSON

public class LegacyImporter : NSObject {
    public struct ImportError : Error {
        let reason : String
        public init(_ reason : String = "") {
            self.reason = reason
        }
    }
    
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
    
    public override init() {
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
        
        group.enter()
        DispatchQueue.global(qos: .background).async {
            self.importRecentlyListenedShows(completion: { blockError in
                if blockError != nil {
                    error = blockError
                }
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("PhishOD legacy import complete")
            completion(error)
        }
    }

    func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        fatalError("Must be implemented by subclass")
    }
    
    func importLegacyFavoriteShows(completion: @escaping (Error?) -> Void) {
        fatalError("Must be implemented by subclass")
    }
    
    private func stringForArtistAndDate(artistSlug : String, displayDate : String) -> String {
        return "\(artistSlug).\(displayDate)"
    }
    
    func loadHistoryData() -> Data? {
        var history : Data? = nil
        
        do {
            let historyPath = persistedObjectsPath + "/current.history"
            let historyURL = URL(fileURLWithPath: historyPath)
            history = try Data(contentsOf: historyURL)
        } catch { }
        
        return history
    }
    
    func importRecentlyListenedShows(completion: @escaping (Error?) -> Void) {
        var error : Error? = nil
        let completionGroup = DispatchGroup()
        let mappingGroup = DispatchGroup()
        
        let artistsAndShows : [(String, String)]
        do {
            artistsAndShows = try loadRecentlyListenedShowsFromDisk()
        } catch {
            completion(ImportError("Couldn't load recently listened shows from disk"))
            return
        }
        var artistAndDateStringToCompleteShow : [String : CompleteShowInformation] = [:]
        
        // First build up all of the CompleteShowInformations for the favorites
        completionGroup.enter()
        for (artistSlug, displayDate) in artistsAndShows {
            mappingGroup.enter()
            self.legacyMapper.getCompleteShowForDate(displayDate, artist: artistSlug) { (showInfo, blockError) in
                if let showInfo = showInfo {
                    let showKey = self.stringForArtistAndDate(artistSlug: artistSlug, displayDate: displayDate)
                    artistAndDateStringToCompleteShow[showKey] = showInfo
                } else {
                    if blockError != nil {
                        error = blockError
                    } else {
                        error = LegacyMapper.GenericImportError()
                    }
                }
                mappingGroup.leave()
            }
        }
        
        mappingGroup.notify(queue: DispatchQueue.global(qos: .background)) {
            // Run the import in order
            for (artistSlug, displayDate) in artistsAndShows {
                let showKey = self.stringForArtistAndDate(artistSlug: artistSlug, displayDate: displayDate)
                self.debug("Importing recently listened show \(showKey)")
                if let showInfo = artistAndDateStringToCompleteShow[showKey] {
                    let imported = MyLibrary.shared.importRecentlyPlayedShow(showInfo)
                    if imported == false {
                        error = LegacyMapper.GenericImportError()
                    }
                } else {
                    if error == nil {
                        error = LegacyMapper.GenericImportError()
                    }
                }
                
            }
            completionGroup.leave()
        }
        
        completionGroup.notify(queue: DispatchQueue.global(qos: .background)) {
            self.debug("Import for recently played shows is complete")
            self.cleanupLegacyFiles()
            completion(error)
        }
    }
    
    private func loadRecentlyListenedShowsFromDisk() throws -> [(String, String)] {
        var retval : [(String, String)] = []
        if let historyData = self.loadHistoryData() {
            let decoder = try NSKeyedUnarchiver(forReadingFrom: historyData)
            decoder.setClass(IGShow.self, forClassName: "IGShow")
            decoder.setClass(PHODHistory.self, forClassName: "PHODHistory")
            decoder.setClass(PhishinShow.self, forClassName: "PhishinShow")
            if let history : PHODHistory = try decoder.decodeTopLevelObject(forKey: "root") as? PHODHistory {
                retval = history.shows.compactMap({
                    if let artistSlug = $0.artistSlug,
                        let displayDate = $0.displayDate {
                        return (artistSlug, displayDate)
                    } else {
                        return nil
                    }
                })
            }
        } else {
            throw LegacyMapper.GenericImportError()
        }
        return retval
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
        } catch {
            self.debug("Error removing legacy files at path \(persistedObjectsPath): \(error)")
        }
    }

    // MARK: Helpers
    func debug(_ str : String) {
        LogDebug("[Import] " + str)
    }
    
    func warning(_ str : String) {
        LogWarn("[Import] " + str)
    }
    
    func legacyCachePathExists() -> Bool {
        var isDir : ObjCBool = false
        return (fm.fileExists(atPath: cachePath, isDirectory: &isDir) && isDir.boolValue)
    }
    
    func deleteDirectoryIfEmpty(_ path : String) {
        do {
            if fm.fileExists(atPath: path), try fm.contentsOfDirectory(atPath: path).count == 0 {
                try fm.removeItem(atPath: path)
            }
        } catch {
            warning("Error while removing show directory at \(path): \(error)")
        }
    }
    
    func allSubdirsAtPath(_ path : String) -> [String] {
        var retval : [String] = []
        
        guard fm.fileExists(atPath: path) else {
            return retval
        }

        do {
            for subdirectory in try fm.contentsOfDirectory(atPath: path) {
                var isDir : ObjCBool = false
                if fm.fileExists(atPath: path + "/" + subdirectory, isDirectory: &isDir), isDir.boolValue {
                    retval.append(subdirectory)
                }
            }
        } catch let error {
            warning("Exception while getting subdirectories at \(path): \(error)")
        }
        
        return retval
    }
}

protocol LegacyShowWrapper : class {
    var displayDate : String? { get }
    var artistSlug : String? { get }
}

@objc(IGShow) public class IGShow : NSObject, NSCoding, LegacyShowWrapper {
    var json : SwJSON?
    var artistID : Int?
    var artistSlug : String?
    var displayDate : String? { get { return legacyShow?.displayDate } }
    var legacyShow : LegacyShow?
    
    required public init?(coder aDecoder: NSCoder) {
        let jsonString = aDecoder.decodeObject(forKey: "json") as? String
        if let jsonString = jsonString {
            json = JSON(parseJSON: jsonString)
            if let json = json {
                artistID = json["artist"]["id"].int
                artistSlug = json["artist"]["slug"].string
                legacyShow = LegacyShow(json: json)
            }
        }
    }
    
    public func encode(with aCoder: NSCoder) { }
}

@objc(PhishinShow) public class PhishinShow : NSObject, NSCoding, LegacyShowWrapper {
    var artistSlug : String? = "phish"
    var displayDate: String?
    
    required public init?(coder aDecoder: NSCoder) {
        displayDate = aDecoder.decodeObject(forKey: "date") as? String
    }
    
    public func encode(with aCoder: NSCoder) { }
}

extension LegacyShow {
    public convenience init(_ show : IGShow) {
        self.init(json: JSON())
    }
}

@objc(PHODHistory) public class PHODHistory : NSObject, NSCoding {
    let shows : [LegacyShowWrapper]
    required public init?(coder aDecoder: NSCoder) {
        shows = aDecoder.decodeObject(forKey: "history") as? [LegacyShowWrapper] ?? []
    }
    
    public func encode(with aCoder: NSCoder) {
    }
}
