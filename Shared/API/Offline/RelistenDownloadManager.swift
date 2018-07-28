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
    func trackSizeBecameKnown(_ track: Track, fileSize: UInt64)
    func trackBecameAvailableOffline(_ track: Track)
}

public class RelistenDownloadManager {
    public static let shared = RelistenDownloadManager()
    
    public weak var delegate: RelistenDownloadManagerDelegate? = nil
    
    public let eventTrackStartedDownloading = Event<Track>()
    public let eventTracksQueuedToDownload = Event<[Track]>()
    public let eventTrackFinishedDownloading = Event<Track>()
    public let eventTracksDeleted = Event<[Track]>()

    fileprivate var urlToTrackMap: [URL: Track] = [:]
    
    private let initQueue : DispatchQueue = DispatchQueue(label: "live.relisten.ios.mp3-offline.queue")
    private var backingDownloadManager : MZDownloadManager?
    lazy var downloadManager: MZDownloadManager = {
        initQueue.sync {
            if (backingDownloadManager == nil) {
                backingDownloadManager = MZDownloadManager(session: "live.relisten.ios.mp3-offline", delegate: self)
            }
        }
        return backingDownloadManager!
    }()
    
    private func downloadModelForTrack(_ track: Track) -> MZDownloadModel? {
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
    
    public func delete(showInfo: CompleteShowInformation) {
        let tracks = showInfo.completeTracksFlattened
        
        for track in tracks {
            delete(track: track, saveOffline: false)
        }
        
        MyLibraryManager.shared.library.saveOfflineTrackUrls()
        eventTracksDeleted.raise(tracks)
        MyLibraryManager.shared.library.saveDownloadBacklog()
    }
    
    public func delete(track: Track, saveOffline: Bool = true) {
        MyLibraryManager.shared.library.URLNotAvailableOffline(track, save: saveOffline)
        
        if let index = MyLibraryManager.shared.library.downloadBacklog.index(of: track) {
            MyLibraryManager.shared.library.downloadBacklog.remove(at: index)
        }
        
        if track.downloadState == .downloading {
            for (idx, downloadModel) in downloadManager.downloadingArray.enumerated() {
                if downloadModel.downloadingURL == track.mp3_url {
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
        let tracks = show.completeTracksFlattened
        
        for track in tracks {
            let availableOffline = MyLibraryManager.shared.library.isTrackAvailableOffline(track)
            let currentlyDownloading = isTrackQueuedToDownload(track) || isTrackActivelyDownloading(track)
            
            if !availableOffline && !currentlyDownloading {
                download(track: track, raiseEvent: false)
            }
        }
        
        eventTracksQueuedToDownload.raise(tracks)
    }
    
    private func addDownloadTask(_ track: Track) {
        downloadManager.addDownloadTask(downloadFilename(forTrack: track), fileURL: track.mp3_url.absoluteString, destinationPath: downloadFolder)
    }
    
    public func download(track: Track, raiseEvent: Bool = true) {
        if downloadManager.downloadingArray.count < 3 {
            urlToTrackMap[track.mp3_url] = track

            addDownloadTask(track)
        }
        else {
            MyLibraryManager.shared.library.queueToBacklog(track)
        }
        
        eventTracksQueuedToDownload.raise([ track ])
    }
    
    let downloadFolder: String
    let statusLabel: MarqueeLabel

    func downloadFilename(forURL url: URL) -> String {
        let filename = MD5(url.absoluteString)! + ".mp3"
        return filename
    }
    
    func downloadFilename(forTrack track: Track) -> String {
        return downloadFilename(forURL: track.mp3_url)
    }
    
    func downloadFilename(forSourceTrack sourceTrack: SourceTrack) -> String {
        return downloadFilename(forURL: sourceTrack.mp3_url)
    }
    
    func downloadPath(forURL url: URL) -> String {
        return downloadFolder + "/" + downloadFilename(forURL: url)
    }
    
    func downloadPath(forTrack track: Track) -> String {
        return downloadPath(forURL: track.mp3_url)
    }
    
    func downloadPath(forSourceTrack sourceTrack: SourceTrack) -> String {
        return downloadPath(forURL: sourceTrack.mp3_url)
    }
    
    public func offlineURL(forTrack track: Track) -> URL? {
        if MyLibraryManager.shared.library.isTrackAvailableOffline(track) {
            return URL(fileURLWithPath: downloadPath(forTrack: track))
        }
        
        return nil
    }
    
    public func isTrackQueuedToDownload(_ track: Track) -> Bool {
        if let dl = downloadModelForTrack(track) {
            if dl.status != TaskStatus.downloading.description() {
                return true
            }
        }
        
        for backlogTrack in MyLibraryManager.shared.library.downloadBacklog {
            if backlogTrack.mp3_url == track.mp3_url {
                return true
            }
        }
        
        return false
    }

    public func isTrackActivelyDownloading(_ track: Track) -> Bool {
        if let dl = downloadModelForTrack(track) {
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
