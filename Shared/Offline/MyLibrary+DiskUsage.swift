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
