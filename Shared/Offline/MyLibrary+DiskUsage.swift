//
//  MyLibrary+DiskUsage.swift
//  Relisten
//
//  Created by Alec Gorge on 5/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

extension MyLibrary {
    // this can return non-nil even when isTrackAvailableOffline returns false
    // this will also be non-nil if isTrackAvailableOffline return true
    private func offlineMetadata(forTrack track: SourceTrack) -> OfflineTrack? {
        return realm.object(ofType: OfflineTrack.self, forPrimaryKey: track.uuid)
    }
    
    public func diskUsageForTrackURL(track: SourceTrack, _ callback: @escaping (UInt64?) -> Void) {
        if let meta = offlineMetadata(forTrack: track), let size = meta.file_size.value {
            return callback(UInt64(size))
        }
        let filesizeBlock = {
            do {
                let offlinePath = RelistenDownloadManager.shared.downloadPath(forURL: track.mp3_url)
                
                guard FileManager.default.fileExists(atPath: offlinePath) else {
                    callback(nil)
                    
                    return
                }
                
                let attributes = try FileManager.default.attributesOfItem(atPath: offlinePath)
                let fileSize = attributes[FileAttributeKey.size] as! UInt64
                
                // put it in the cache so subsequent calls are hot
                self.trackSizeBecameKnown(track, fileSize: fileSize)
                callback(fileSize)
            }
            catch {
                print(error)
                
                callback(nil)
            }
        }
        
        if DispatchQueue.getSpecific(key: diskUseQueueKey) != nil {
            filesizeBlock()
        } else {
            diskUseQueue.async(execute: filesizeBlock)
        }
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
