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

public protocol RelistenAppDelegate {
    var rootNavigationController: ASNavigationController! { get }
}

public class RelistenApp {
    public static let sharedApp = RelistenApp(delegate: RelistenDummyAppDelegate())
    
    public var delegate : RelistenAppDelegate
    
    public init(delegate: RelistenAppDelegate) {
        self.delegate = delegate
    }
    
    public func setupThirdPartyDependencies() {
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
    public var rootNavigationController: ASNavigationController! {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
}
