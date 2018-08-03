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
    private func offlineMetadata(forTrackURL trackURL: URL) -> OfflineTrackMetadata? {
        do {
            return try offlineTrackFileSizeCache.object(forKey: trackURL.absoluteString)
        }
        catch {
            return nil
        }
    }
    
    public func diskUsageForTrackURL(trackURL: URL, _ callback: @escaping (UInt64?) -> Void) {
        if let meta = offlineMetadata(forTrackURL: trackURL) {
            return callback(meta.fileSize)
        }
        let filesizeBlock = {
            do {
                let offlinePath = RelistenDownloadManager.shared.downloadPath(forURL: trackURL)
                
                guard FileManager.default.fileExists(atPath: offlinePath) else {
                    callback(nil)
                    
                    return
                }
                
                let attributes = try FileManager.default.attributesOfItem(atPath: offlinePath)
                let fileSize = attributes[FileAttributeKey.size] as! UInt64
                
                // put it in the cache so subsequent calls are hot
                self.trackSizeBecameKnown(trackURL: trackURL, fileSize: fileSize)
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
    
    public func diskUsageForSource(source: CompleteShowInformation, _ callback: @escaping (_ diskUsage: UInt64, _ numberOfTracks: Int) -> Void) {
        diskUseQueue.async {
            var completeBytes: UInt64 = 0
            var numberOfTracks: Int = 0
            
            let group = DispatchGroup()
            let bytesQueue = DispatchQueue(label: "live.relisten.library.diskUsage.bytesQueue")
            
            for track in source.source.tracksFlattened {
                group.enter()
                self.diskUsageForTrackURL(trackURL: track.mp3_url, { (size) in
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
