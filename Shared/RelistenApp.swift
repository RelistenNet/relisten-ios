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
    
    var isDummyDelegate : Bool { get }
}

public class RelistenApp {
    public static let sharedApp = RelistenApp(delegate: RelistenDummyAppDelegate())
    
    public let launchScreenBounds: CGRect
    
    public let shakeToReportBugEnabled = Observable<Bool>(true)
    public var playbackController : PlaybackController! { didSet {
            if oldValue != nil {
                playbackController.inheritObservables(fromPlaybackController: oldValue)
            }
        }
    }
    
    public var delegate : RelistenAppDelegate {
        didSet {
            playbackController?.window = delegate.window
        }
    }
    
    public static let logDirectory : String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true).first! + "/Logs"
    }()
    
    public static let appName : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            return "Relisten"
        }
        return retval
    }()
    
    public static let appVersion : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0"
        }
        return retval
    }()
    
    public static let appBuildVersion : String = {
        guard let retval = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "0"
        }
        return retval
    }()
    
    public var appIcon : UIImage {
        get {
            return delegate.appIcon
        }
    }
    
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
        self.delegate = delegate
        
        self.launchScreenBounds = UIScreen.main.bounds

        if let enableBugReporting = UserDefaults.standard.object(forKey: bugReportingKey) as! Bool? {
            shakeToReportBugEnabled.value = enableBugReporting
        }
        
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
        playbackController = PlaybackController(withWindow: delegate.window)
        
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
    
    public func loadViews() {
        AppColorObserver.observe { [weak self] (_, _) in
            DispatchQueue.main.async {
                self?.setupAppearance()
            }
        }.add(to: &disposal)
        
        playbackController.viewDidLoad()
    }
    
    public func setupThirdPartyDependencies() {
        #if targetEnvironment(simulator)
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            LogDebug("Documents Directory: \(documentsPath)")
        }
        #endif
    }
    
    public func setupAppearance() {
        let _ = RatingViewStubBounds
        
        UINavigationBar.appearance().barTintColor = AppColors.primary
        UINavigationBar.appearance().backgroundColor = AppColors.textOnPrimary
        UINavigationBar.appearance().tintColor = AppColors.textOnPrimary
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary]
        
        UIToolbar.appearance().backgroundColor = AppColors.primary
        UIToolbar.appearance().tintColor = AppColors.textOnPrimary
        
        UIButton.appearance().tintColor = AppColors.primary
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = AppColors.textOnPrimary
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary], for: .normal)
        
        UISegmentedControl.appearance().tintColor = AppColors.primary
        UITabBar.appearance().tintColor = AppColors.primary
        
        let sutf = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        sutf.defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        sutf.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        let sbbi = UISegmentedControl.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        
        sbbi.tintColor = AppColors.textOnPrimary
        sbbi.backgroundColor = AppColors.primary

        if !delegate.isDummyDelegate,
           let nav = delegate.rootNavigationController {
            nav.navigationBar.barTintColor = AppColors.primary
            nav.navigationBar.backgroundColor = AppColors.primary
            nav.navigationBar.tintColor = AppColors.primary
        }
        
        playbackController?.viewController.applyColors(AppColors.playerColors)
    }
}

public extension RelistenAppDelegate {
    public var isDummyDelegate : Bool { get { return false } }
}

public class RelistenDummyAppDelegate : RelistenAppDelegate {
    // The window ivar is requested by the playback controller. It's ok for it to be nil, so let's just return nil here and not complain.
    public var window: UIWindow? = nil
    public var isDummyDelegate = true
    
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
