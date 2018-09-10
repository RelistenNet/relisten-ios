//
//  UserFeedback.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import PinpointKit
import CWStatusBarNotification
import Realm

public class UserFeedback  {
    static public let shared = UserFeedback()
    
    let pinpointKit : PinpointKit
    var screenshotDetector : ScreenshotDetector?
    var currentNotification : CWStatusBarNotification?
    
    public init() {
        let versionString = "Relisten \(RelistenApp.sharedApp.appVersion) (\(RelistenApp.sharedApp.appBuildVersion))"
        var feedbackConfig = FeedbackConfiguration(recipients: ["ios@relisten.net"])
        feedbackConfig.title = "[Bug Report: \(versionString)]"
        feedbackConfig.body = "\n\n\nConfiguration Information (Please don't delete):\n\t\(versionString)\n\tCrash log identifier \(RelistenApp.sharedApp.crashlyticsUserIdentifier)"
        let config = Configuration(logCollector: RelistenLogCollector(), feedbackConfiguration: feedbackConfig)
        pinpointKit = PinpointKit(configuration: config)
    }
    
    public func setup() {
        screenshotDetector = ScreenshotDetector(delegate: self)
    }
    
    public func presentFeedbackView(from vc: UIViewController? = nil, screenshot : UIImage? = nil) {
        guard let viewController = vc ?? RelistenApp.sharedApp.delegate.rootNavigationController else { return }
        
        if let screenshot = screenshot {
            currentNotification?.dismiss()
            pinpointKit.show(from: viewController, screenshot: screenshot)
        } else {
            currentNotification?.dismiss() {
                // If I grab the screenshot immediately there's still a tiny line from the notification animating away. If I let the runloop run for just a bit longer then the screenshot doesn't pick up that turd.
                DispatchQueue.main.async {
                    self.pinpointKit.show(from: viewController, screenshot: Screenshotter.takeScreenshot())
                }
            }
        }
    }
    
    public func requestUserFeedback(from vc : UIViewController? = nil, screenshot : UIImage? = nil) {
        currentNotification?.dismiss()
        
        let notification = CWStatusBarNotification()
        notification.notificationTappedBlock = {
            self.presentFeedbackView(screenshot: screenshot)
        }
        notification.notificationStyle = .navigationBarNotification
        notification.notificationLabelBackgroundColor = AppColors.highlight
        notification.notificationLabelFont = UIFont.preferredFont(forTextStyle: .headline)
        
        currentNotification = notification
        currentNotification?.display(withMessage: "🐞 Tap here to report a bug 🐞", forDuration: 3.0)
    }
}

extension UserFeedback : ScreenshotDetectorDelegate {
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didDetect screenshot: UIImage) {
        requestUserFeedback(screenshot: screenshot)
    }
    
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didFailWith error: ScreenshotDetector.Error) {
        
    }
}

class RelistenLogCollector : LogCollector {
    public func retrieveLogs() -> [String] {
        var retval : [String] = []
        let fm = FileManager.default
        let logDir = RelistenApp.sharedApp.logDirectory
        
        // List offline tracks
        do {
            var isDir : ObjCBool = false
            if fm.fileExists(atPath: DownloadManager.shared.downloadFolder, isDirectory: &isDir), isDir.boolValue {
                retval.append("======= Offline Files =======")
                for file in try fm.contentsOfDirectory(atPath: DownloadManager.shared.downloadFolder) {
                    retval.append("\t\(file)")
                }
                retval.append("======= End Offline Files =======\n\n")
            }
        } catch {
            LogWarn("Error enumerating downloaded tracks: \(error)")
        }
        
        let group = DispatchGroup()
        group.enter()
      
        // Force a new thread so that Realm doesn't try to reuse an instance which errors out
        // becuase no other instances use `dynamic = true`
        let realmThread = Thread {
            do {
                let config = RLMRealmConfiguration()
                config.dynamic = true
                
                let realm = try RLMRealm.init(configuration: config)
                let exporter = CSVDataExporter(realm: realm)
                
                let tempDir = try self.createTemporaryDirectoy().path
                
                defer {
                    do {
                        try fm.removeItem(atPath: tempDir)
                    } catch {
                        LogError("Caugh error: \(error)")
                        LogError("Could not clean up \(tempDir)")
                    }
                }
                
                try exporter.export(toFolderAtPath: tempDir)
                
                let csvs = try fm.contentsOfDirectory(atPath: tempDir)
                
                for csvFile in csvs {
                    let data = try String(contentsOfFile: tempDir + "/" + csvFile, encoding: .utf8)
                    retval.append("======= Realm Table Dump (\(csvFile)) =======")
                    retval.append(contentsOf: data.components(separatedBy: .newlines))
                    retval.append("======= End Realm Table Dump (\(csvFile)) =======\n\n")
                }
            } catch {
                LogWarn("Unable to dump Realm tables: \(error)")
            }
            
            group.leave()
        }
        
        realmThread.start()
        
        group.wait()
        
        // Grab the latest log file
        autoreleasepool {
            do {
                if let logFile = try fm.contentsOfDirectory(atPath: logDir).sorted(by: { return $0 > $1 }).first {
                    let data = try String(contentsOfFile: logDir + "/" + logFile, encoding: .utf8)
                    retval.append("======= Latest Log File (\(logFile)) =======")
                    retval.append(contentsOf: data.components(separatedBy: .newlines))
                    retval.append("======= End Latest Log File (\(logFile)) =======\n\n")
                }
            } catch {
                LogWarn("Couldn't read log file at \(logDir): \(error)")
            }
        }
        
        return retval
    }
    
    func createTemporaryDirectoy() throws -> URL{
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
}
