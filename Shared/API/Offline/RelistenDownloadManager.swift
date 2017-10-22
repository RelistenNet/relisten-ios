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
import MarqueeLabel

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
        
        statusLabel = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        statusLabel.font = UIFont.systemFont(ofSize: 12.0)
        
        try! FileManager.default.createDirectory(atPath: downloadFolder, withIntermediateDirectories: true, attributes: nil)
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
    let statusLabel: MarqueeLabel
    
    func downloadPath(forTrack: SourceTrack) -> String {
        let filename = MD5(forTrack.mp3_url.absoluteString)! + ".mp3"
        return downloadFolder + "/" + filename
    }
    
    public func offlineURL(forTrack: SourceTrack) -> URL? {
        if MyLibraryManager.sharedInstance.isTrackAvailableOffline(track: forTrack) {
            return URL(fileURLWithPath: downloadPath(forTrack: forTrack))
        }
        
        return nil
    }
    
    public func isTrackDownloading(_ track: SourceTrack) -> Bool {
        return downloadManager.downloadingArray.contains(where: { $0.fileURL == track.mp3_url.absoluteString })
    }
}

extension RelistenDownloadManager : MZDownloadManagerDelegate {
    public func downloadRequestDidUpdateProgress(_ downloadModel: MZDownloadModel, index: Int) {
        let txt = "Downloading \"\(downloadModel.fileName!)\" \((downloadModel.progress * 100.0).rounded())% (\(downloadManager.downloadingArray.count - index) left)"
        
        statusLabel.text = txt
        print(txt)
        notificationBar.display(with: statusLabel, completion: nil)
    }
    
    public func downloadRequestDidPopulatedInterruptedTasks(_ downloadModel: [MZDownloadModel]) {
        // notificationBar.display(withMessage: "Restoring \(downloadModel.count) downloads", completion: nil)
    }
    
    public func downloadRequestStarted(_ downloadModel: MZDownloadModel, index: Int) {
        notificationBar.display(with: statusLabel, completion: nil)
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
        try! FileManager.default.moveItem(atPath: location.path, toPath: downloadModel.destinationPath)
    }
}
