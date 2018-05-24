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
    public func offlineMetadataForTrack(track: SourceTrack) -> OfflineTrackMetadata? {
        do {
            return try offlineTrackFileSizeCache.object(ofType: OfflineTrackMetadata.self, forKey: track.mp3_url.absoluteString)
        }
        catch {
            return nil
        }
    }
    
    public func diskUsageForTrack(track: SourceTrack, _ callback: @escaping (UInt64?) -> Void) {
        if let meta = offlineMetadataForTrack(track: track) {
            return callback(meta.fileSize)
        }
        
        if isTrackAvailableOffline(track: track) {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let offlinePath = RelistenDownloadManager.shared.downloadPath(forTrack: track)
                    
                    guard FileManager.default.fileExists(atPath: offlinePath) else {
                        callback(nil)
                        
                        return
                    }
                    
                    let attributes = try FileManager.default.attributesOfItem(atPath: offlinePath)
                    let fileSize = attributes[FileAttributeKey.size] as! UInt64
                    
                    // put it in the cache so subsequent calls are hot
                    self.urlSizeBecameKnown(url: track.mp3_url, fileSize: fileSize)
                    
                    callback(fileSize)
                }
                catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        RelistenNotificationBar.display(withMessage: error.localizedDescription, forDuration: 10)
                    }
                    
                    callback(nil)
                }
            }
        }
        else {
            callback(nil)
        }
    }
    
    public func diskUsageForSource(source: SourceFull, _ callback: @escaping (UInt64?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tracks = source.tracksFlattened
            
            var completeBytes: UInt64 = 0
            
            let semaphore = DispatchSemaphore(value: 0)
            
            for track in tracks {
                self.diskUsageForTrack(track: track, { (size) in
                    if let bytes = size {
                        synced(completeBytes) {
                            completeBytes += bytes
                            semaphore.signal()
                        }
                    }
                    else {
                        semaphore.signal()
                    }
                })
            }
            
            for _ in tracks {
                semaphore.wait()
            }
            
            callback(completeBytes)
        }
    }
}
