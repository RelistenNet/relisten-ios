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

public struct DownloadError : Error {
    let reason : String
    public init(_ reason : String = "") {
        self.reason = reason
    }
}

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
    func offlineTrackFailedDownloading(_ track: Track, error: Error?)
    func importDownloadedTrack(_ track : Track, withSize fileSize: UInt64)
    
    func nextTrackToDownload() -> Track?
    func tracksToDownload(_ count : Int) -> [Track]?
    func currentlyDownloadingTracks() -> [Track]?
    
    func deleteAllTracks(_ completion : @escaping () -> Void)
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
        if (backingDownloadManager == nil) {
            queue.sync {
                if (backingDownloadManager == nil) {
                    let sessionConfiguration = MZDownloadManager.defaultSessionConfiguration(identifier: "live.relisten.ios.mp3-offline")
                    sessionConfiguration.timeoutIntervalForRequest = 60.0
                    sessionConfiguration.timeoutIntervalForResource = 60.0 * 60.0 * 24
                    sessionConfiguration.httpMaximumConnectionsPerHost = 3
                    backingDownloadManager = MZDownloadManager(session: "live.relisten.ios.mp3-offline", delegate: self, sessionConfiguration: sessionConfiguration)
                }
            }
        }
        return backingDownloadManager!
    }()
    
    lazy var downloadFolder: String = {
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
                let filePath = track.downloadPath
                
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                    self.dataSource?.offlineTrackWasDeleted(track)
                    
                    if shouldNotify {
                        self.eventTracksDeleted.raise([track])
                    }
                }
                catch {
                    LogWarning("Error when removing downloaded track: \(error)")
                }
            }
        }
    }
    
    public func deleteAllDownloads(_ completion: @escaping () -> Void) {
        queue.async {
            LogDebug("⚠️🗑 Deleting all downloaded tracks!")
            
            // Cancel all outstanding downloads
            for i in 0..<self.downloadManager.downloadingArray.count {
                self.downloadManager.cancelTaskAtIndex(i)
            }
            
            // Delete everything in the db
            let group = DispatchGroup()
            if let dataSource = self.dataSource {
                group.enter()
                dataSource.deleteAllTracks {
                    group.leave()
                }
            }
            
            
            group.notify(queue: self.queue.queue) {
                // Delete everything on the filesystem just to be sure
                do {
                    try FileManager.default.removeItem(atPath: self.downloadFolder)
                } catch {
                    LogWarn("Error deleting downloaded tracks from the filesystem: \(error)")
                }
                do {
                    try FileManager.default.createDirectory(atPath: self.downloadFolder, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    LogWarn("Error creating download directory on the filesystem: \(error)")
                }
                
                DispatchQueue.global().async {
                    LogDebug("⚠️🗑 Finished deleting all tracks")
                    completion()
                }
            }
        }
    }
    
    private func trackNeedsDownload(_ track : Track) -> Bool {
        let availableOffline = MyLibrary.shared.isTrackAvailableOffline(track)
        let currentlyDownloading = isTrackQueuedToDownload(track) || isTrackActivelyDownloading(track)
        
        if currentlyDownloading {
            return false
        }
        
        if availableOffline {
            // make sure the file exists returning true to indicate download is needed if not
            return !FileManager.default.fileExists(atPath: track.downloadPath)
        }
        
        return true
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
        downloadManager.addDownloadTask(track.downloadFilename, fileURL: url.absoluteString, destinationPath: downloadFolder)
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
            } else {
                self.dataSource?.offlineTrackQueuedToBacklog(track)

                fillDownloadQueue(withTrack: track)
                
                if raiseEvent {
                    eventTracksQueuedToDownload.raise([ track ])
                }
            }
        }
        
        return retval
    }
    
    func importDownloadedTrack(_ track : Track, filePath : String) {
        queue.sync {
            LogDebug("Importing track \"\(track.title) - (\(track.showInfo.artist.name) \(track.showInfo.show.display_date))\" from \(filePath)...")
            
            let fm = FileManager.default
            do {
                
                var fileSize : UInt64 = 0
                do {
                    let attributes = try fm.attributesOfItem(atPath: filePath)
                    fileSize = attributes[.size] as! UInt64
                } catch {
                    LogWarn("Error getting file size for file at \(filePath): \(error)")
                }
                
                try fm.moveItem(atPath: filePath, toPath: track.downloadPath)
                
                self.dataSource?.importDownloadedTrack(track, withSize: fileSize)
                self.eventTrackFinishedDownloading.raise(track)
            } catch {
                LogWarn("Error importing track: \(error)")
            }
        }
    }

    func downloadFilename(forURL url: URL) -> String {
        let filename = MD5(url.absoluteString)! + ".mp3"
        return filename
    }
    
    func downloadPath(forURL url: URL) -> String {
        return downloadFolder + "/" + downloadFilename(forURL: url)
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
    
    private func fileToActualBytes(_ file: (size: Float, unit: String)) -> UInt64 {
        let multiplier: Float
        
        if file.size < 0 { return 0 }
        
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
        
        return UInt64(file.size * multiplier)
    }
    
    public func downloadRequestStarted(_ downloadModel: MZDownloadModel, index: Int) {
        LogDebug("Started downloading: \(downloadModel)")
        
        if let t = self.trackForDownloadModel(downloadModel) {
            eventTrackStartedDownloading.raise(t)
            self.dataSource?.offlineTrackBeganDownloading(t)
        }
    }
    
    func responseHasExpectedContentType(_ downloadModel: MZDownloadModel) -> Bool {
        if let headerFields = (downloadModel.task?.response as? HTTPURLResponse)?.allHeaderFields {
            let contentTypeHeaders = headerFields.filter({
                if let (header, _) = $0 as? (String, Any) {
                    return header.lowercased() == "content-type"
                }
                return false
            })
            
            if let (_, contentType) = contentTypeHeaders.first as? (AnyHashable, String) {
                if contentType.lowercased().hasPrefix("audio") {
                    return true
                } else {
                    LogWarn("Content type \(contentType) is not what was expected. Treating download of \(downloadModel.fileURL ?? "[unkown URL]") as an error")
                    return false
                }
            }
        }
        
        // We're intentionally being loose here. If the server was nice enough to return content-type then we'll enforce that it's an audio type.
        // Otherwise, let's just let it slide and hope for the best, since it would be a shame to incorrectly drop downloads because the server didn't return
        //  a content-type header.
        return true
    }
    
    public func downloadRequestFinished(_ downloadModel: MZDownloadModel, index: Int) {
        LogDebug("Finished downloading: \(downloadModel)")
        
        var error : Error? = nil
        
        // Check the content type to make sure we didn't get an error page
        if !responseHasExpectedContentType(downloadModel) {
            error = DownloadError("Content type is not what was expected. Treating download of \(downloadModel.fileURL ?? "[unkown URL]") as an error")
        }
        
        if let t = self.trackForDownloadModel(downloadModel) {
            if error == nil {
                var fileSize : UInt64 = 0
                if let file = downloadModel.file {
                    fileSize = fileToActualBytes(file)
                }
                dataSource?.offlineTrackFinishedDownloading(t, withSize: fileSize)
            } else {
                dataSource?.offlineTrackFailedDownloading(t, error: error)
            }
                
            eventTrackFinishedDownloading.raise(t)
            
            self.removeTrackForDownloadModel(downloadModel)
        }
        
        queue.async {
            self.fillDownloadQueue()
        }
    }
    
    public func downloadRequestDidFailedWithError(_ error: NSError, downloadModel: MZDownloadModel, index: Int) {
        LogDebug("Download request failed with error: \(error)")
        var didReplaceFile = false
        
        // Handle cases where a file is getting redownloaded but it already exists in the offline directory
        if error.domain == NSCocoaErrorDomain, error.code == 516 {
            if let sourceFile = error.userInfo["NSSourceFilePathErrorKey"] as? String,
               let destinationFile = error.userInfo["NSDestinationFilePath"] as? String{
                let fm = FileManager.default
                do {
                    let sourceFileURL = URL(fileURLWithPath: sourceFile)
                    let destinationFileURL = URL(fileURLWithPath: destinationFile)
                    let destinationFileName = destinationFileURL.lastPathComponent + ".bak"
                    let _ = try fm.replaceItemAt(sourceFileURL, withItemAt: destinationFileURL, backupItemName: destinationFileName, options: .usingNewMetadataOnly)
                    didReplaceFile = true
                } catch {
                    LogWarn("Couldn't replace item at \(destinationFile) with \(sourceFile)")
                }
            }
        }
        
        if let t = trackForDownloadModel(downloadModel) {
            if didReplaceFile {
                var fileSize : UInt64 = 0
                if let file = downloadModel.file {
                    fileSize = fileToActualBytes(file)
                }
                dataSource?.offlineTrackFinishedDownloading(t, withSize: fileSize)
            } else {
                dataSource?.offlineTrackFailedDownloading(t, error: error)
            }
            
            eventTrackFinishedDownloading.raise(t)
        }
        
        self.removeTrackForDownloadModel(downloadModel)
        
        queue.async {
            self.fillDownloadQueue()
        }
    }
    
    public func downloadRequestDestinationDoestNotExists(_ downloadModel: MZDownloadModel, index: Int, location: URL) {
        do {
            try FileManager.default.moveItem(atPath: location.path, toPath: downloadModel.destinationPath)
        } catch {
            LogError("\(error)")
        }
    }
}

extension MZDownloadModel {
    public var downloadingURL: URL {
        return URL(string: fileURL)!
    }
}

extension Track {
    public var downloadFilename : String {
        get {
            return DownloadManager.shared.downloadFilename(forURL: self.mp3_url)
        }
    }
    
    public var downloadPath : String {
        get {
            return DownloadManager.shared.downloadPath(forURL: self.mp3_url)
        }
    }
        
    
    public var offlineURL : URL? {
        get {
            if MyLibrary.shared.isTrackAvailableOffline(self) {
                return URL(fileURLWithPath: self.downloadPath)
            }
            return nil
        }
    }
}

extension SourceTrack {
    public var downloadFilename : String {
        get {
            return DownloadManager.shared.downloadFilename(forURL: self.mp3_url)
        }
    }
    
    public var downloadPath : String {
        get {
            return DownloadManager.shared.downloadPath(forURL: self.mp3_url)
        }
    }
    
    
    public var offlineURL : URL? {
        get {
            if MyLibrary.shared.isTrackAvailableOffline(self) {
                return URL(fileURLWithPath: self.downloadPath)
            }
            return nil
        }
    }
}
