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

public protocol RelistenDownloadManagerDelegate: class {
    func urlSizeBecameKnown(url: URL, fileSize: UInt64)
    func urlBecameAvailableOffline(url: URL)
}

let RelistenNotificationBar: CWStatusBarNotification = CWStatusBarNotification()

public class RelistenDownloadManager {
    public static let shared = RelistenDownloadManager()
    
    public weak var delegate: RelistenDownloadManagerDelegate? = nil
    
    public let eventTrackStartedDownloading = Event<SourceTrack>()
    public let eventTracksQueuedToDownload = Event<[SourceTrack]>()
    public let eventTrackFinishedDownloading = Event<SourceTrack>()
    public let eventTracksDeleted = Event<[SourceTrack]>()

    fileprivate var urlToTrackMap: [URL: SourceTrack] = [:]
    
    lazy var downloadManager: MZDownloadManager = {
        return MZDownloadManager(session: "live.relisten.ios.mp3-offline", delegate: self)
    }()
    
    private func downloadModelForTrack(track: SourceTrack) -> MZDownloadModel? {
        for dlModel in downloadManager.downloadingArray {
            if URL(string: dlModel.fileURL)! == track.mp3_url {
                return dlModel
            }
        }
        
        return nil
    }
    
    public init() {
        downloadFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                             FileManager.SearchPathDomainMask.userDomainMask,
                                                             true).first! + "/" + "offline-mp3s"
        
        statusLabel = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        statusLabel.font = UIFont.systemFont(ofSize: 12.0)
        
        try! FileManager.default.createDirectory(atPath: downloadFolder, withIntermediateDirectories: true, attributes: nil)        
    }
    
    public func delete(source: SourceFull) {
        let tracks = source.tracksFlattened
        for track in tracks {
            delete(track: track, saveOffline: false)
        }
        
        MyLibraryManager.shared.library.saveOfflineTrackUrls()
        eventTracksDeleted.raise(data: tracks)
        MyLibraryManager.shared.library.saveDownloadBacklog()
    }
    
    public func delete(track: SourceTrack, saveOffline: Bool = true) {
        MyLibraryManager.shared.library.URLNotAvailableOffline(track.mp3_url, save: saveOffline)
        
        if let index = MyLibraryManager.shared.library.downloadBacklog.index(of: track) {
            MyLibraryManager.shared.library.downloadBacklog.remove(at: index)
        }
        
        if isTrackActivelyDownloading(track) {
            for (idx, downloadModel) in downloadManager.downloadingArray.enumerated() {
                if downloadModel.downloadingURL == track.mp3_url {
                    downloadManager.cancelTaskAtIndex(idx)
                }
            }
        }

        if saveOffline {
            eventTracksDeleted.raise(data: [track])
            
            MyLibraryManager.shared.library.saveDownloadBacklog()
        }
        
        DispatchQueue.global(qos: .background).async {
            let file = self.downloadPath(forTrack: track)
            
            do {
                try FileManager.default.removeItem(atPath: file)
            }
            catch {
                print(error)
            }
        }
    }
    
    public func download(show: CompleteShowInformation) {
        for set in show.source.sets {
            for track in set.tracks {
                let availableOffline = MyLibraryManager.shared.library.isTrackAvailableOffline(track: track)
                let currentlyDownloading = isTrackQueuedToDownload(track) || isTrackActivelyDownloading(track)
                
                if !availableOffline && !currentlyDownloading {
                    download(track: track, raiseEvent: false)
                }
            }
        }
        
        eventTracksQueuedToDownload.raise(data: show.source.tracksFlattened)
    }
    
    private func addDownloadTask(_ track: SourceTrack) {
        downloadManager.addDownloadTask(track.title, fileURL: track.mp3_url.absoluteString, destinationPath: downloadPath(forTrack: track))
    }
    
    public func download(track: SourceTrack, raiseEvent: Bool = true) {
        if downloadManager.downloadingArray.count < 3 {
            addDownloadTask(track)
            
            urlToTrackMap[track.mp3_url] = track
        }
        else {
            MyLibraryManager.shared.library.queueToBacklog(track)
        }
        
        eventTracksQueuedToDownload.raise(data: [ track ])
    }
    
    let downloadFolder: String
    let statusLabel: MarqueeLabel
    
    func downloadPath(forTrack: SourceTrack) -> String {
        let filename = MD5(forTrack.mp3_url.absoluteString)! + ".mp3"
        return downloadFolder + "/" + filename
    }
    
    public func offlineURL(forTrack: SourceTrack) -> URL? {
        if MyLibraryManager.shared.library.isTrackAvailableOffline(track: forTrack) {
            return URL(fileURLWithPath: downloadPath(forTrack: forTrack))
        }
        
        return nil
    }
    
    public func isTrackQueuedToDownload(_ track: SourceTrack) -> Bool {
        if let dl = downloadModelForTrack(track: track) {
            if dl.status != TaskStatus.downloading.description() {
                return true
            }
        }
        
        if MyLibraryManager.shared.library.downloadBacklog.contains(track) {
            return true
        }
        
        return false
    }

    public func isTrackActivelyDownloading(_ track: SourceTrack) -> Bool {
        if let dl = downloadModelForTrack(track: track) {
            if dl.status == TaskStatus.downloading.description() {
                return true
            }
        }
        
        return false
    }
}

extension RelistenDownloadManager : MZDownloadManagerDelegate {
    public func downloadRequestDidUpdateProgress(_ downloadModel: MZDownloadModel, index: Int) {
        let txt = "Downloading \"\(downloadModel.fileName!)\" \((downloadModel.progress * 100.0).rounded())% (\(downloadManager.downloadingArray.count - index) left)"
        
        statusLabel.text = txt
        print(txt)
    }
    
    public func downloadRequestDidPopulatedInterruptedTasks(_ downloadModel: [MZDownloadModel]) {
        // notificationBar.display(withMessage: "Restoring \(downloadModel.count) downloads", completion: nil)
    }
    
    private func fileToActualBytes(_ file: (size: Float, unit: String)) -> Float {
        let multiplier: Float
        
        switch file.unit {
        case "GB":
            multiplier = 1024 * 1024 * 1024
        case "MB":
            multiplier = 1024 * 1024
        case "KB":
            multiplier = 1024
        default:
            multiplier = 1
        }
        
        return file.size * multiplier
    }
    
    public func downloadRequestStarted(_ downloadModel: MZDownloadModel, index: Int) {
        if let f = downloadModel.file {
            delegate?.urlSizeBecameKnown(url: URL(string: downloadModel.fileURL)!, fileSize: UInt64(fileToActualBytes(f)))
        }
        else {
            print("Somehow missing the file size from the download model")
        }
        
        print("Started downloading: \(downloadModel)")
        
        if let t = urlToTrackMap[downloadModel.downloadingURL] {
            eventTrackStartedDownloading.raise(data: t)
        }
    }
    
    public func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        print("Finished downloading: \(downloadModel)")
        
        let url = downloadModel.downloadingURL
        if let f = downloadModel.file {
            delegate?.urlSizeBecameKnown(url: url, fileSize: UInt64(fileToActualBytes(f)))
        }
        delegate?.urlBecameAvailableOffline(url: url)
        
        if let t = urlToTrackMap[url] {
            eventTrackFinishedDownloading.raise(data: t)
            
            urlToTrackMap.removeValue(forKey: url)
        }
        
        if let nextTrack = MyLibraryManager.shared.library.dequeueFromBacklog() {
            urlToTrackMap[nextTrack.mp3_url] = nextTrack

            addDownloadTask(nextTrack)
        }
    }
    
    public func downloadRequestDidFailedWithError(_ error: NSError, downloadModel: MZDownloadModel, index: Int) {
        print(error)

        urlToTrackMap.removeValue(forKey: downloadModel.downloadingURL)
        /*
        if let t = urlToTrackMap[URL(string: downloadModel.fileURL)!] {
            eventTrackFinishedDownloading.raise(data: t)
        }
        */
    }
    
    public func downloadRequestDestinationDoestNotExists(_ downloadModel: MZDownloadModel, index: Int, location: URL) {
        try! FileManager.default.moveItem(atPath: location.path, toPath: downloadModel.destinationPath)
    }
}

extension MZDownloadModel {
    public var downloadingURL: URL {
        return URL(string: fileURL)!
    }
}
