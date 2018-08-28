//
//  MyLibrary+DiskUsage.swift
//  Relisten
//
//  Created by Alec Gorge on 5/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import RealmSwift

extension MyLibrary {
    // this can return non-nil even when isTrackAvailableOffline returns false
    // this will also be non-nil if isTrackAvailableOffline return true
    private func offlineMetadata(forTrack track: SourceTrack) -> OfflineTrack? {
        let realm = try! Realm()
        
        return realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid.uuidString)
    }
    
    public func diskUsageForAllTracks(_ callback: @escaping (_ diskUsage: UInt64, _ numberOfTracks: Int) -> Void) {
        diskUseQueue.async {
            var diskUsage : UInt64 = 0
            var numberOfTracks : Int = 0
            for track in self.offline.tracks {
                numberOfTracks += 1
                if let size = track.file_size.value {
                    diskUsage += UInt64(size)
                }
            }
            callback(diskUsage, numberOfTracks)
        }
    }
 
    // This consults the filesystem rather than the database
    public func realDiskUsageForAllTracks(_ callback: @escaping (_ diskUsage: UInt64, _ numberOfTracks: Int) -> Void) {
        diskUseQueue.async {
            var diskUsage : UInt64 = 0
            var numberOfTracks : Int = 0
            let downloadPath = DownloadManager.shared.downloadFolder
            do {
                let fm = FileManager.default
                for file in try fm.contentsOfDirectory(atPath: downloadPath) {
                    let attributes = try fm.attributesOfItem(atPath: downloadPath + "/" + file)
                    numberOfTracks += 1
                    if let size = attributes[FileAttributeKey.size] as! UInt64? {
                        diskUsage += size
                    }
                }
            } catch {
                LogDebug("Exception while checking downloaded files at \(downloadPath): \(error)")
            }
            callback(diskUsage, numberOfTracks)
        }
    }
    
    public func diskUsageForTrackURL(track: SourceTrack, _ callback: @escaping (UInt64?) -> Void) {
        if let meta = offlineMetadata(forTrack: track), let size = meta.file_size.value {
            return callback(UInt64(size))
        }
        
        return callback(nil)
    }
    
    public func diskUsageForSource(source: SourceFull, _ callback: @escaping (_ diskUsage: UInt64, _ numberOfTracks: Int) -> Void) {
        diskUseQueue.async {
            var completeBytes: UInt64 = 0
            var numberOfTracks: Int = 0
            
            let group = DispatchGroup()
            let bytesQueue = DispatchQueue(label: "live.relisten.library.diskUsage.bytesQueue")
            
            for track in source.tracksFlattened {
                group.enter()
                self.diskUsageForTrackURL(track: track, { (size) in
                    if let bytes = size {
                        bytesQueue.sync {
                            numberOfTracks += 1
                            completeBytes += bytes
                        }
                    }
                    group.leave()
                })
            }
            
            group.wait()
            
            callback(completeBytes, numberOfTracks)
        }
    }
}
