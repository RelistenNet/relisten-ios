//
//  AppDelegate.swift
//  PhishOD
//
//  Created by Alec Gorge on 8/9/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import RelistenShared
import SwiftyJSON

import Fabric
import Crashlytics

@UIApplicationMain
class PHODAppDelegate: UIResponder, UIApplicationDelegate, RelistenAppDelegate {

    var window: UIWindow?
    public var rootNavigationController: RelistenNavigationController! = nil
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        SetupLogging()
        
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        LogDebug("⭕️⭕️⭕️ PhishOD is launching ⭕️⭕️⭕️")
        RelistenApp.sharedApp.delegate = self
        
        // cannot be in the shared library :/ https://stackoverflow.com/questions/20495064/how-to-integrate-crashlytics-with-static-library
        Fabric.with([Crashlytics.self])

        RelistenApp.sharedApp.setupThirdPartyDependencies()
        RelistenApp.sharedApp.setupAppearance()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        rootNavigationController = RelistenNavigationController(rootViewController: ArtistViewController(artist: loadPhishArtist()))
        
        rootNavigationController.navigationBar.prefersLargeTitles = true
        rootNavigationController.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: AppColors.textOnPrimary]
        
        window?.rootViewController = rootNavigationController
        
        window?.makeKeyAndVisible()
        
        setupPlayback()
        setupWormholy()
        UserFeedback.shared.setup()
        
        // Initialize CarPlay
        CarPlayController.shared.setup()
        
        // Import data from pre-4.0 versions of the app
        let phishImporter = LegacyPhishODImporter()
        phishImporter.performLegacyImport { (error) in
            LogDebug("PhishOD import completed")
        }
        
        return true
    }
    
    private func loadPhishArtist() -> ArtistWithCounts {
        do {
            if let phishURL = Bundle.main.url(forResource: "Phish", withExtension: "json") {
                let phishJSONData = try Data(contentsOf: phishURL)
                let phishJSON = try JSON(data: phishJSONData)
                let artist = try ArtistWithCounts(json: phishJSON)
                return artist
            }
        } catch {
            LogError("\(error)")
        }
        fatalError("Couldn't load the Phish artist JSON data")
    }
    
    func setupPlayback() {
        PlaybackController.window = window
        let _ = PlaybackController.sharedInstance
        
        DispatchQueue.main.async {
            let _ = DownloadManager.shared
        }
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

