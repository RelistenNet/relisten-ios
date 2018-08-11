//
//  LegacyOfflineTrackImporter.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

enum AppCacheType : String, RawRepresentable {
    case phishOD = "phish.in"
    case relisten = "relisten.net"
}

class LegacyOfflineTrackImporter {
    private lazy var cacheDir : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! +
            "/" + "com.alecgorge.phish.cache" +
            "/" + self.cacheType.rawValue
    }()
    
    private let cacheType : AppCacheType
    
    public init(cacheType : AppCacheType) {
        self.cacheType = cacheType
    }
    
    public func importLegacyOfflineTracks(completion: @escaping (Error?) -> Void) {
        let error : Error? = nil
        let showDates : [(String, String)] = allCachedShowDates()
        let group = DispatchGroup()
        for (slug, showDate) in showDates {
            group.enter()
            artistFromSlug(slug) { artist in
                if let artist = artist {
                    self.loadShowInfoForDate(withSlug: slug, showDate: showDate) { (show) in
                        if let show = show {
                            let foundTracks : [(Track, URL)] = self.findOfflineTracks(forShow: show, artist: artist)
                            for (track, localURL) in foundTracks {
                                var fileSize : UInt64 = 0
                                do {
                                    var attributes = try FileManager.default.attributesOfItem(atPath: localURL.absoluteString)
                                    fileSize = attributes[.size] as! UInt64
                                } catch { }
                                DownloadManager.shared.importDownloadedTrack(track, withSize: fileSize)
                            }
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            completion(error)
        }
    }
    
    private func allCachedShowDates() -> [(slug : String, date : String)] {
        var retval : [(String, String)] = []
        if cacheType == .relisten {
            // (farkas) Relisten legacy import isn't supported at this time since it would require calls to the old API to match up show/track identifiers
            return retval
        }
        let curArtist = "phish"
        
        let fm = FileManager.default
        
        do {
            var isDir : ObjCBool = false
            if fm.fileExists(atPath: cacheDir, isDirectory: &isDir), isDir.boolValue {
                for showDirectory in try fm.contentsOfDirectory(atPath: self.cacheDir) {
                    isDir = false
                    if fm.fileExists(atPath: cacheDir + "/" + showDirectory, isDirectory: &isDir), isDir.boolValue {
                        retval.append((curArtist, showDirectory))
                    }
                }
            }
        } catch let error as NSError {
            print("Exception while searching for shows at \(cacheDir): \(error)")
        }
        
        return retval
    }
    
    private func getSlug(_ slug : String?) -> String {
        var _artistSlug = slug
        if _artistSlug == nil {
            if cacheType == .phishOD {
                _artistSlug = "phish"
            } else {
                _artistSlug = "unknown"
            }
        }
        return _artistSlug!
    }
    
    private func loadArtist(withSlug slug : String? = nil, completion : @escaping ((SlimArtist?) -> Void)) {
        let artistSlug = getSlug(slug)
        
        let res = RelistenApi.artist(withSlug: artistSlug)
        res.addObserver(owner: self) { (res, _) in
            completion(res.typedContent())
        }
    }
    
    private func loadShowInfoForDate(withSlug slug : String? = nil, showDate : String, completion : @escaping ((ShowWithSources?) -> Void)) {
        loadArtist(withSlug: slug) { (artist) in
            if let artist = artist {
                let res = RelistenApi.show(onDate: showDate, byArtist: artist)
                res.addObserver(owner: self) { (res, _) in
                    completion(res.typedContent())
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func findOfflineTracks(forShow show : ShowWithSources, artist: Artist) -> [(Track, URL)] {
        var retval : [(Track, URL)] = []
        
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
                for offlineFile in try fm.contentsOfDirectory(atPath: showDir) {
                    if let track = lastURLComponentsToTracks[offlineFile] {
                        let fileURL = URL(fileURLWithPath: showDir + "/" + offlineFile)
                        retval.append((track, fileURL))
                    }
                }
            }
        } catch let error as NSError {
            print("Exception while searching for shows at \(cacheDir): \(error)")
        }
        
        return retval
    }
    
    private var artistsBySlug : [String : ArtistWithCounts] = [:]
    private func artistFromSlug(_ slug : String, completion : @escaping ((ArtistWithCounts?) -> Void)) {
        let artistSlug = getSlug(slug)
        if let retval = artistsBySlug[slug] {
            completion(retval)
            return
        }
        
        let res = RelistenApi.artists()
        res.addObserver(owner: self) { (res, _) in
            var foundArtist : ArtistWithCounts? = nil
            if let artists : [ArtistWithCounts] = res.typedContent() {
                for artist in artists {
                    if artist.slug == artistSlug {
                        foundArtist = artist
                        break
                    }
                }
            }
            if let foundArtist = foundArtist {
                self.artistsBySlug[slug] = foundArtist
            }
            completion(foundArtist)
        }
    }
    
}
