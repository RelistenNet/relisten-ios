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
//import DWURecyclingAlert

import RealmSwift

public protocol RelistenAppDelegate {
    var rootNavigationController: RelistenNavigationController! { get }
    var appIcon : UIImage { get }
    var isPhishOD : Bool { get }
}

public class RelistenApp {
    public static let sharedApp = RelistenApp(delegate: RelistenDummyAppDelegate())
    
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
    
    public init(delegate: RelistenAppDelegate) {
        self.delegate = delegate
        
        DownloadManager.shared.dataSource = MyLibrary.shared
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
