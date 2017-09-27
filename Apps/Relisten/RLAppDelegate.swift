//
//  AppDelegate.swift
//  Relisten
//
//  Created by Alec Gorge on 8/9/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
// import Firebase
// import FirebaseAuth
import DWURecyclingAlert

// public var FirebaseRemoteConfig: RemoteConfig! = nil

public let AppColors = _AppColors(
    primary: UIColor(red:0, green:0.616, blue:0.753, alpha:1),
    textOnPrimary: UIColor.white,
    soundboard: UIColor(red:0.0/255.0, green:128.0/255.0, blue:95.0/255.0, alpha:1.0),
    remaster: UIColor(red:0, green:0.616, blue:0.753, alpha:1),
    mutedText: UIColor.gray
)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func setupThirdPartyDependencies() {
//        Inject_DWURecyclingAlert()

        /*
        FirebaseApp.configure()

        FirebaseRemoteConfig = RemoteConfig.remoteConfig()
        FirebaseRemoteConfig.setDefaults(["api_base": "https://api.relisten.live" as NSObject])
        
        if Auth.auth().currentUser == nil {
            print("No current user. Signing in.")
            Auth.auth().signInAnonymously(completion: { (u, err) in
                print("Signed into Firebase: \(String(describing: u)) \(String(describing: err))")
            })
        }
        */
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        setupThirdPartyDependencies()
        setupAppearance()
        
        window = UIWindow(frame: UIScreen.main.bounds)

        let nav = UINavigationController(rootViewController: ArtistsViewController(useCache: true, refreshOnAppear: false))
        
        if #available(iOS 11.0, *) {
            nav.navigationBar.prefersLargeTitles = true
            nav.navigationBar.largeTitleTextAttributes = [NSForegroundColorAttributeName: AppColors.textOnPrimary]
        }
        
        window?.rootViewController = nav
        
        window?.makeKeyAndVisible()
        
        setupPlayback()
        
        return true
    }
    
    func setupPlayback() {
        PlaybackController.window = window
    }
    
    func setupAppearance() {
        UIApplication.shared.statusBarStyle = .lightContent
        
        UINavigationBar.appearance().barTintColor = AppColors.primary
        UINavigationBar.appearance().backgroundColor = AppColors.primary
        UINavigationBar.appearance().tintColor = AppColors.textOnPrimary
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: AppColors.textOnPrimary]
        
        UIToolbar.appearance().backgroundColor = AppColors.primary
        UIToolbar.appearance().tintColor = AppColors.textOnPrimary
        
        UIButton.appearance().tintColor = AppColors.primary
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: AppColors.textOnPrimary], for: .normal)
        
        UISegmentedControl.appearance().tintColor = AppColors.primary
        UITabBar.appearance().tintColor = AppColors.primary
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

