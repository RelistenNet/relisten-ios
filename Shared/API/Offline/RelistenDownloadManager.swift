//
//  RelistenDownloadManager.swift
//  Relisten
//
//  Created by Alec Gorge on 10/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Cache
import SwiftyJSON
import MZDownloadManager
import CWStatusBarNotification

func MD5(_ string: String) -> String? {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digest = [UInt8](repeating: 0, count: length)
    if let d = string.data(using: String.Encoding.utf8) {
        let _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
            CC_MD5(body, CC_LONG(d.count), &digest)
        }
    }
    return (0..<length).reduce("") {
        $0 + String(format: "%02x", digest[$1])
    }
}

public class RelistenDownloadManager {
    public static let sharedInstance = RelistenDownloadManager()
    
    lazy var downloadManager: MZDownloadManager = {
        return MZDownloadManager(session: "live.relisten.ios.mp3-offline", delegate: self)
    }()
    
    let notificationBar: CWStatusBarNotification = CWStatusBarNotification()
    
    public init() {
        downloadFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                             FileManager.SearchPathDomainMask.userDomainMask,
                                                             true).first! + "/" + "offline-mp3s"
    }
    
    public func download(show: CompleteShowInformation) {
        for set in show.source.sets {
            for track in set.tracks {
                if !MyLibraryManager.sharedInstance.isTrackAvailableOffline(track: track) {
                    download(track: track, fromShow: show)
                }
            }
        }
    }
    
    public func download(track: SourceTrack, fromShow show: CompleteShowInformation) {
        downloadManager.addDownloadTask(track.title, fileURL: track.mp3_url.absoluteString, destinationPath: downloadPath(forTrack: track))
    }
    
    let downloadFolder: String
    
    func downloadPath(forTrack: SourceTrack) -> String {
        let filename = MD5(forTrack.mp3_url.absoluteString)! + ".mp3"
        return downloadFolder + "/" + filename
    }
    
    public func isTrackDownloading(_ track: SourceTrack) -> Bool {
        return downloadManager.downloadingArray.contains(where: { $0.fileURL == track.mp3_url.absoluteString })
    }
}

extension RelistenDownloadManager : MZDownloadManagerDelegate {
    public func downloadRequestDidUpdateProgress(_ downloadModel: MZDownloadModel, index: Int) {
        notificationBar.display(withMessage: "Downloading \"\(downloadModel.fileName)\" \((downloadModel.progress * 100).rounded())% (\(downloadManager.downloadingArray.count - index) left)", completion: nil)
    }
    
    public func downloadRequestDidPopulatedInterruptedTasks(_ downloadModel: [MZDownloadModel]) {
        notificationBar.display(withMessage: "Restoring \(downloadModel.count) downloads", completion: nil)
    }
    
    public func downloadRequestStarted(_ downloadModel: MZDownloadModel, index: Int) {
        print("Started downloading: \(downloadModel)")
    }
    
    public func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        print("Finished downloading: \(downloadModel)")
        
        MyLibraryManager.sharedInstance.URLIsAvailableOffline(URL(string: downloadModel.fileURL)!)
        notificationBar.dismiss()
    }
    
    public func downloadRequestDidFailedWithError(_ error: NSError, downloadModel: MZDownloadModel, index: Int) {
        notificationBar.display(withMessage: "Error: \(error)", completion: nil)
    }
    
    public func downloadRequestDestinationDoestNotExists(_ downloadModel: MZDownloadModel, index: Int, location: URL) {
        print("404: \(index):\(location): \(downloadModel)")
    }
}
