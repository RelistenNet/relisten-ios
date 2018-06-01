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
    func trackSizeBecameKnown(_ track: CompleteTrackShowInformation, fileSize: UInt64)
    func trackBecameAvailableOffline(_ track: CompleteTrackShowInformation)
}

let RelistenNotificationBar: CWStatusBarNotification = CWStatusBarNotification()

public class RelistenDownloadManager {
    public static let shared = RelistenDownloadManager()
    
    public weak var delegate: RelistenDownloadManagerDelegate? = nil
    
    public let eventTrackStartedDownloading = Event<CompleteTrackShowInformation>()
    public let eventTracksQueuedToDownload = Event<[CompleteTrackShowInformation]>()
    public let eventTrackFinishedDownloading = Event<CompleteTrackShowInformation>()
    public let eventTracksDeleted = Event<[CompleteTrackShowInformation]>()

    fileprivate var urlToTrackMap: [URL: CompleteTrackShowInformation] = [:]
    
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
    
    public func delete(source: CompleteShowInformation) {
        let tracks = source.source.completeTracksFlattened(forShow: source)
        
        for track in tracks {
            delete(track: track, saveOffline: false)
        }
        
        MyLibraryManager.shared.library.saveOfflineTrackUrls()
        eventTracksDeleted.raise(tracks)
        MyLibraryManager.shared.library.saveDownloadBacklog()
    }
    
    public func delete(track: CompleteTrackShowInformation, saveOffline: Bool = true) {
        MyLibraryManager.shared.library.URLNotAvailableOffline(track, save: saveOffline)
        
        if let index = MyLibraryManager.shared.library.downloadBacklog.index(of: track) {
            MyLibraryManager.shared.library.downloadBacklog.remove(at: index)
        }
        
        if track.track.isActivelyDownloading {
            for (idx, downloadModel) in downloadManager.downloadingArray.enumerated() {
                if downloadModel.downloadingURL == track.track.track.mp3_url {
                    downloadManager.cancelTaskAtIndex(idx)
                }
            }
        }

        if saveOffline {
            eventTracksDeleted.raise([track])
            
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
        let tracks = show.source.completeTracksFlattened(forShow: show)
        
        for track in tracks {
            let availableOffline = MyLibraryManager.shared.library.isTrackAvailableOffline(track: track.track.track)
            let currentlyDownloading = isTrackQueuedToDownload(track.track.track) || isTrackActivelyDownloading(track.track.track)
            
            if !availableOffline && !currentlyDownloading {
                download(track: track, raiseEvent: false)
            }
        }
        
        eventTracksQueuedToDownload.raise(tracks)
    }
    
    private func addDownloadTask(_ track: CompleteTrackShowInformation) {
        downloadManager.addDownloadTask(track.track.track.title, fileURL: track.track.track.mp3_url.absoluteString, destinationPath: downloadPath(forTrack: track))
    }
    
    public func download(track: CompleteTrackShowInformation, raiseEvent: Bool = true) {
        if downloadManager.downloadingArray.count < 3 {
            addDownloadTask(track)
            
            urlToTrackMap[track.track.track.mp3_url] = track
        }
        else {
            MyLibraryManager.shared.library.queueToBacklog(track)
        }
        
        eventTracksQueuedToDownload.raise([ track ])
    }
    
    let downloadFolder: String
    let statusLabel: MarqueeLabel
    
    func downloadPath(forTrack: CompleteTrackShowInformation) -> String {
        let filename = MD5(forTrack.track.track.mp3_url.absoluteString)! + ".mp3"
        return downloadFolder + "/" + filename
    }
    
    public func offlineURL(forTrack: CompleteTrackShowInformation) -> URL? {
        if MyLibraryManager.shared.library.isTrackAvailableOffline(track: forTrack.track.track) {
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
        
        for backlogTrack in MyLibraryManager.shared.library.downloadBacklog {
            if backlogTrack.track.track.mp3_url == track.mp3_url {
                return true
            }
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
        print("Started downloading: \(downloadModel)")
        
        if let t = urlToTrackMap[downloadModel.downloadingURL] {
            if let f = downloadModel.file {
                delegate?.trackSizeBecameKnown(t, fileSize: UInt64(fileToActualBytes(f)))
            }
            else {
                print("Somehow missing the file size from the download model")
            }

            eventTrackStartedDownloading.raise(t)
        }
    }
    
    public func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        print("Finished downloading: \(downloadModel)")
        
        let url = downloadModel.downloadingURL
        
        if let t = urlToTrackMap[url] {
            if let f = downloadModel.file {
                delegate?.trackSizeBecameKnown(t, fileSize: UInt64(fileToActualBytes(f)))
            }
            delegate?.trackBecameAvailableOffline(t)

            eventTrackFinishedDownloading.raise(t)
            
            urlToTrackMap.removeValue(forKey: url)
        }
        
        if let nextTrack = MyLibraryManager.shared.library.dequeueFromBacklog() {
            urlToTrackMap[nextTrack.track.track.mp3_url] = nextTrack

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
