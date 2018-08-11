//
//  DownloadManager.swift
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
import Observable

import RealmSwift

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

public protocol DownloadManagerDataSource : class {
    func offlineTrackWillBeDeleted(_ track: Track)
    func offlineTrackQueuedToBacklog(_ track: Track)
    func offlineTrackWasDeleted(_ track: Track)
    func offlineTrackBeganDownloading(_ track: Track)
    func offlineTrackFinishedDownloading(_ track: Track, withSize fileSize: UInt64)
    
    func nextTrackToDownload() -> Track?
    func tracksToDownload(_ count : Int) -> [Track]?
    func currentlyDownloadingTracks() -> [Track]?
}

public class TrackDownload {
    public let track : Track
    public var url : URL { get { return self.track.mp3_url } }
    public let progress = Observable<Float>(0.0)
    public weak var model : MZDownloadModel?
    public var disposal = Disposal()
    
    public init(track: Track) {
        self.track = track
    }
    
    public func setProgress(_ progress : Float) {
        self.progress.value = progress
    }
}

public class DownloadManager {
    public static let shared = DownloadManager()
    
    public weak var dataSource: DownloadManagerDataSource? = nil {
        didSet {
            self.queue.async {
                self.startQueuedDownloads()
            }
        }
    }
    
    public let eventTrackStartedDownloading = Event<Track>()
    public let eventTracksQueuedToDownload = Event<[Track]>()
    public let eventTrackFinishedDownloading = Event<Track>()
    public let eventTracksDeleted = Event<[Track]>()

    fileprivate var urlToTrackDownloadMap: [URL: TrackDownload] = [:]
    
    private let queue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.ios.mp3-offline.queue")
    private var backingDownloadManager : MZDownloadManager?
    lazy var downloadManager: MZDownloadManager = {
        queue.sync {
            if (backingDownloadManager == nil) {
                backingDownloadManager = MZDownloadManager(session: "live.relisten.ios.mp3-offline", delegate: self)
            }
        }
        return backingDownloadManager!
    }()
    
    private lazy var downloadFolder: String = {
        let folder = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         FileManager.SearchPathDomainMask.userDomainMask,
                                                         true).first! + "/" + "offline-mp3s"
        // This would probably be better done on a background queue, but I'm afraid of the race conditions on the first download attempt
        try! FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        return folder
    }()
    
    private func startQueuedDownloads() {
        queue.assertQueue()
        
        // Reset anything marked as downloading that isn't in our download manager. These were probably left over from an app crash
        if let downloadingTracks = dataSource?.currentlyDownloadingTracks() {
            for track in downloadingTracks {
                self.dataSource?.offlineTrackQueuedToBacklog(track)
            }
        }
        
        fillDownloadQueue()
    }
    
    public func delete(showInfo: CompleteShowInformation) {
        queue.async {
            let tracks = showInfo.completeTracksFlattened
            
            for track in tracks {
                self.delete(track: track, shouldNotify: false)
            }
            
            self.eventTracksDeleted.raise(tracks)
        }
    }
    
    public func delete(track: Track, shouldNotify: Bool = true) {
        queue.async {
            self.dataSource?.offlineTrackWillBeDeleted(track)
            
            if track.downloadState == .downloading {
                for (idx, downloadModel) in self.downloadManager.downloadingArray.enumerated() {
                    if downloadModel.downloadingURL == track.mp3_url {
                        self.downloadManager.cancelTaskAtIndex(idx)
                    }
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                let file = self.downloadPath(forTrack: track)
                
                do {
                    try FileManager.default.removeItem(atPath: file)
                    self.dataSource?.offlineTrackWasDeleted(track)
                    
                    if shouldNotify {
                        self.eventTracksDeleted.raise([track])
                    }
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    private func trackNeedsDownload(_ track : Track) -> Bool {
        let availableOffline = MyLibrary.shared.isTrackAvailableOffline(track)
        let currentlyDownloading = isTrackQueuedToDownload(track) || isTrackActivelyDownloading(track)
        
        return !availableOffline && !currentlyDownloading
    }
    
    public func download(show: CompleteShowInformation) {
        let tracks : [Track] = show.completeTracksFlattened
        var queuedTracks : [Track]  = []
        
        queue.sync {
            for track in tracks {
                let willDownload = download(track: track, raiseEvent: false)
                if willDownload {
                    queuedTracks.append(track)
                }
            }
        }
        
        eventTracksQueuedToDownload.raise(queuedTracks)
    }
    
    private func addDownloadTask(_ track: Track) {
        queue.assertQueue()
        
        let url = track.mp3_url
        urlToTrackDownloadMap[url] = TrackDownload(track: track)
        downloadManager.addDownloadTask(downloadFilename(forTrack: track), fileURL: url.absoluteString, destinationPath: downloadFolder)
    }
    
    private func fillDownloadQueue(withTrack track : Track? = nil) {
        queue.assertQueue()
        if let track = track, downloadManager.downloadingArray.count < 3 {
            addDownloadTask(track)
        }
        
        let downloadQueueSlots = 3 - downloadManager.downloadingArray.count
        // Resume any queued downloads
        if downloadQueueSlots > 0 {
            if let tracksToDownload = dataSource?.tracksToDownload(downloadQueueSlots) {
                for track in tracksToDownload {
                    addDownloadTask(track)
                }
                
                eventTracksQueuedToDownload.raise(tracksToDownload)
            }
        }
    }
    
    public func download(track: Track, raiseEvent: Bool = true) -> Bool {
        var retval = true
        queue.sync {
            if !trackNeedsDownload(track) {
                retval = false
            }
            
            self.dataSource?.offlineTrackQueuedToBacklog(track)

            fillDownloadQueue(withTrack: track)
            
            if raiseEvent {
                eventTracksQueuedToDownload.raise([ track ])
            }
        }
        
        return retval
    }

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
        if MyLibrary.shared.isTrackAvailableOffline(track) {
            return URL(fileURLWithPath: downloadPath(forTrack: track))
        }
        
        return nil
    }
    
    private func downloadModelForTrack(_ track: Track) -> MZDownloadModel? {
        var retval : MZDownloadModel? = nil
        
        queue.sync {
            for dlModel in downloadManager.downloadingArray {
                if URL(string: dlModel.fileURL)! == track.mp3_url {
                    retval = dlModel
                    break
                }
            }
        }
        
        return retval
    }
    
    private func trackForDownloadModel(_ model: MZDownloadModel) -> Track? {
        var retval : Track? = nil
        queue.sync {
            if let trackDownload = urlToTrackDownloadMap[model.downloadingURL] {
                retval = trackDownload.track
            }
        }
        return retval
    }
    
    private func removeTrackForDownloadModel(_ model: MZDownloadModel) {
        queue.sync {
            urlToTrackDownloadMap.removeValue(forKey: model.downloadingURL)
        }
    }
    
    public func isTrackQueuedToDownload(_ track: Track) -> Bool {
        if let dl = downloadModelForTrack(track) {
            if dl.status != TaskStatus.downloading.description() {
                return true
            }
        }
        
        for backlogTrack in MyLibrary.shared.downloadBacklog {
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
    
    public func observeProgressForTrack(_ track: Track, observer: @escaping (Float) -> Void) {
        queue.sync {
            if let trackDownload = urlToTrackDownloadMap[track.mp3_url] {
                trackDownload.progress.observe({ (progress, _) in
                    observer(progress)
                }).add(to: &trackDownload.disposal)
            }
        }
    }
}

// MARK: MZDownloadManagerDelegate
extension DownloadManager : MZDownloadManagerDelegate {
    public func downloadRequestDidUpdateProgress(_ downloadModel: MZDownloadModel, index: Int) {
        queue.sync {
            if let trackDownload = urlToTrackDownloadMap[downloadModel.downloadingURL] {
                trackDownload.progress.value = downloadModel.progress
            }
        }
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
        
        if let t = self.trackForDownloadModel(downloadModel) {
            eventTrackStartedDownloading.raise(t)
            self.dataSource?.offlineTrackBeganDownloading(t)
        }
    }
    
    public func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        print("Finished downloading: \(downloadModel)")
        
        if let t = self.trackForDownloadModel(downloadModel) {
            dataSource?.offlineTrackFinishedDownloading(t, withSize: UInt64(fileToActualBytes(downloadModel.file!)))

            eventTrackFinishedDownloading.raise(t)
            
            self.removeTrackForDownloadModel(downloadModel)
        }
        
        queue.async {
            self.fillDownloadQueue()
        }
    }
    
    public func downloadRequestDidFailedWithError(_ error: NSError, downloadModel: MZDownloadModel, index: Int) {
        print(error)

        self.removeTrackForDownloadModel(downloadModel)
        
        if let t = trackForDownloadModel(downloadModel) {
            eventTrackFinishedDownloading.raise(t)
        }
        
        queue.async {
            self.fillDownloadQueue()
        }
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
