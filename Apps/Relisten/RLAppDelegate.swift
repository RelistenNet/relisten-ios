//
//  AppDelegate.swift
//  Relisten
//
//  Created by Alec Gorge on 8/9/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

import UIKit
import RelistenShared

import Siesta
import SVProgressHUD
import AsyncDisplayKit

import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RelistenAppDelegate {

    var window: UIWindow?
    public var rootNavigationController: ASNavigationController! = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        RelistenApp.sharedApp.delegate = self
        
        // cannot be in the shared library :/ https://stackoverflow.com/questions/20495064/how-to-integrate-crashlytics-with-static-library
        Fabric.with([Crashlytics.self])
        
        RelistenApp.sharedApp.setupThirdPartyDependencies()
        RelistenApp.sharedApp.setupAppearance()
        
        window = UIWindow(frame: UIScreen.main.bounds)

        rootNavigationController = ASNavigationController(rootViewController: ArtistsViewController())
        
        rootNavigationController.navigationBar.prefersLargeTitles = true
        rootNavigationController.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: AppColors.textOnPrimary]
        
        window?.rootViewController = rootNavigationController
        
        window?.makeKeyAndVisible()
        
        setupPlayback()
        
        // Initialize CarPlay
        CarPlayController.shared.setup()
        
        // Import data from pre-4.0 versions of the app
        let relistenImporter = LegacyRelistenImporter()
        relistenImporter.performLegacyImport { (error) in
            print("Relisten import completed")
        }
        
        return true
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

extension AppDelegate {
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL!
            
            // https://relisten.net/grateful-dead/1967/02/12/smokestack-lightning?source=87690
            
            let parts = url.pathComponents
            
            let artistsVc = rootNavigationController.viewControllers.first! as! ArtistsViewController
            var vcs: [UIViewController] = [ artistsVc ]
            
            guard let artists = artistsVc.latestData else {
                return true
            }
            
            var artist: ArtistWithCounts! = nil
            
            if parts.count >= 2 {
                // specific artist
                
                artist = artists.first(where: { $0.slug == parts[1] })
                
                vcs.append(ArtistViewController(artist: artist))
            }
            
            func doneMakingViewControllers() {
                SVProgressHUD.dismiss()
                
                rootNavigationController.setViewControllers(vcs, animated: false)
            }
            
            if parts.count >= 3 {
                vcs.append(YearsViewController(artist: artist))
                
                // year only
                if parts.count < 5 {
                    
                    let res = RelistenApi.years(byArtist: artist)
                    
                    SVProgressHUD.show()
                    res.addObserver(owner: self) { (res, event) in
                        if let years: [Year] = res.typedContent(), let yearObj = years.filter({ $0.year == parts[2] }).first {
                            vcs.append(YearViewController(artist: artist, year: yearObj))
                            
                            res.removeObservers(ownedBy: self)
                            
                            doneMakingViewControllers()
                        }
                    }
                    res.load()
                }
            }
            else {
                doneMakingViewControllers()
            }
            
            if parts.count >= 5 {
                let res = RelistenApi.show(onDate: parts[2] + "-" + parts[3] + "-" + parts[4], byArtist: artist)

                SVProgressHUD.show()
                res.addObserver(owner: self) { (res, event) in
                    if let show: ShowWithSources = res.typedContent() {
                        vcs.append(YearViewController(artist: artist, year: show.year))
                        vcs.append(SourcesViewController(artist: artist, show: show))
                        
                        if let queryString = url.query?.split(separator: "&") {
                            var sourceId: Int? = nil
                            
                            for param in queryString {
                                let kvs = String(param).split(separator: "=")
                                
                                if let f = kvs.first, String(f) == "source", let l = kvs.last {
                                    sourceId = Int(String(l))
                                }
                            }
                            
                            if let sourceId = sourceId, let source = show.sources.filter({ $0.id == sourceId }).first {
                                vcs.append(SourceViewController(artist: artist, show: show, source: source))
                            }
                        }
                        
                        res.removeObservers(ownedBy: self)
                        
                        doneMakingViewControllers()
                    }
                }
                res.load()
            }
            
            print(url.absoluteString)
            //handle url
        }
        return true
    }
}
