//
//  RelistenApp.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/25/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit
import Observable
import RealmSwift
import Crashlytics

public protocol RelistenAppDelegate {
    var window : UIWindow? { get }
    var rootNavigationController: RelistenNavigationController! { get }
    
    var appIcon : UIImage { get }
    var isPhishOD : Bool { get }
}

public class RelistenApp {
    public static let sharedApp = RelistenApp(delegate: RelistenDummyAppDelegate())
    
    public let shakeToReportBugEnabled = Observable<Bool>(true)
    
    public var delegate : RelistenAppDelegate
    public lazy var logDirectory : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! + "/Logs"
    }()
    
    public lazy var appName : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return "Relisten"
        }
        return retval
    }()
    
    public var appIcon : UIImage {
        get {
            return delegate.appIcon
        }
    }
    
    public lazy var appVersion : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0"
        }
        return retval
    }()
    
    public lazy var appBuildVersion : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "0"
        }
        return retval
    }()
    
    public var isPhishOD : Bool  {
        get {
            return delegate.isPhishOD
        }
    }
    public var launchCount : Int {
        if let launchCount = UserDefaults.standard.object(forKey: launchCountKey) as! Int? {
            return launchCount
        }
        return 0
    }
    
    public var crashlyticsUserIdentifier : String {
        get {
            if let retval = UserDefaults.standard.object(forKey: crashlyticsUserIdentifierKey) as! String? {
                return retval
            } else {
                let userIdentifier = UUID().uuidString
                UserDefaults.standard.set(userIdentifier, forKey: crashlyticsUserIdentifierKey)
                return userIdentifier
            }
        }
    }
    
    let bugReportingKey = "EnableBugReporting"
    let launchCountKey = "LaunchCount"
    let crashlyticsUserIdentifierKey = "UserIdentifier"
    
    var disposal = Disposal()
    public init(delegate: RelistenAppDelegate) {
        MyLibrary.migrateRealmDatabase()

        if let enableBugReporting = UserDefaults.standard.object(forKey: bugReportingKey) as! Bool? {
            shakeToReportBugEnabled.value = enableBugReporting
        }
        self.delegate = delegate
        
        if let launchCount = UserDefaults.standard.object(forKey: launchCountKey) as! Int? {
            UserDefaults.standard.set(launchCount + 1, forKey: launchCountKey)
        } else {
            UserDefaults.standard.set(1, forKey: launchCountKey)
        }
        
        DownloadManager.shared.dataSource = MyLibrary.shared
        
        shakeToReportBugEnabled.observe { (new, _) in
            UserDefaults.standard.set(new, forKey: self.bugReportingKey)
        }.add(to: &disposal)
    }
    
    public func sharedSetup() {
        if let window = delegate.window {
            PlaybackController.window = window
        }
        let _ = PlaybackController.sharedInstance
        
        DispatchQueue.main.async {
            let _ = DownloadManager.shared
        }
        
        setupWormholy()
        UserFeedback.shared.setup()
        
        let userIdentifier = self.crashlyticsUserIdentifier
        LogDebug("Setting Crashlytics user identifier to \(userIdentifier)")
        Crashlytics.sharedInstance().setUserIdentifier(userIdentifier)
        
        if !self.isPhishOD {
            // Initialize CarPlay
            CarPlayController.shared.setup()
        }
    }
    
    public func setupThirdPartyDependencies() {
        #if targetEnvironment(simulator)
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            LogDebug("Documents Directory: \(documentsPath)")
        }
        #endif
    }
    
    public func setupAppearance(_ viewController: UINavigationController? = nil) {
        let _ = RatingViewStubBounds
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        UINavigationBar.appearance().barTintColor = AppColors.primary
        UINavigationBar.appearance().backgroundColor = AppColors.textOnPrimary
        UINavigationBar.appearance().tintColor = AppColors.textOnPrimary
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: AppColors.textOnPrimary]
        
        UIToolbar.appearance().backgroundColor = AppColors.primary
        UIToolbar.appearance().tintColor = AppColors.textOnPrimary
        
        UIButton.appearance().tintColor = AppColors.primary
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = AppColors.textOnPrimary
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: AppColors.textOnPrimary], for: .normal)
        
        UISegmentedControl.appearance().tintColor = AppColors.primary
        UITabBar.appearance().tintColor = AppColors.primary
        
        if let nav = viewController {
            nav.navigationBar.barTintColor = AppColors.primary
            nav.navigationBar.backgroundColor = AppColors.primary
            nav.navigationBar.tintColor = AppColors.primary
        }
    }
}

public class RelistenDummyAppDelegate : RelistenAppDelegate {
    public var window: UIWindow? {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
    
    public var rootNavigationController: RelistenNavigationController! {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
    
    public var appIcon : UIImage {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
    
    public var isPhishOD : Bool {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
}
