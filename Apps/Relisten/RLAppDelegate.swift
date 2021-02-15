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

import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RelistenAppDelegate, GCKLoggerDelegate {

    var window: UIWindow?
    public var rootNavigationController: RelistenNavigationController! = nil
    public lazy var appIcon : UIImage = {
        let infoDictionary = Bundle.main.infoDictionary
        
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)!
        }
        
        fatalError()
    }()
    public let isPhishOD : Bool = false
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SetupLogging()
        
        LogDebug("🔊🔊🔊 Relisten is launching 🔊🔊🔊")
        RelistenApp.sharedApp.delegate = self
        
        // cannot be in the shared library :/ https://stackoverflow.com/questions/20495064/how-to-integrate-crashlytics-with-static-library
        Fabric.with([Crashlytics.self])
        
        RelistenApp.sharedApp.setupThirdPartyDependencies()
        
        // Set up Chromecast support
        let criteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        GCKCastContext.setSharedInstanceWith(options)
        GCKLogger.sharedInstance().delegate = self
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // (farkas) Yuck. We have to get the standard switch bounds on the main thread, and state restoration means we might try to get it on load which deadlocks with other Texture stuff running on the main thread.
        SwitchCellNode.loadStandardSwitchBounds()
        
        RelistenApp.sharedApp.sharedSetup()
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if rootNavigationController == nil {
            let artists = ArtistsViewController()
            let nav = RelistenNavigationController(rootViewController: artists)
            nav.tabBarItem = artists.tabBarItem
            
            rootNavigationController = nav
        }
        
        rootNavigationController.navigationBar.prefersLargeTitles = true
        rootNavigationController.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary]
        
        window?.rootViewController = RelistenTabBarController(rootNavigationController)
        
        window?.makeKeyAndVisible()
        RelistenApp.sharedApp.loadViews()
        RelistenApp.sharedApp.setupAppearance()
        
        // Import data from pre-4.0 versions of the app
        let relistenImporter = LegacyRelistenImporter()
        relistenImporter.performLegacyImport { (error) in
            LogDebug("Relisten import completed")
        }
        
        if launchOptions != nil,
           let url = launchOptions![.url] as? URL {
            self.handleURL(url: url)
        }
        
        return true
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

// MARK: State Restoration
extension AppDelegate {
    public func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    public func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        // TODO: If it's been over N hours and the user wasn't playing music, should we go back to the main screen?
        return true
    }
    
    public func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
        // TODO: Encode the PlaybackController state here
    }
    
    public func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
        // TODO: Decode the PlaybackController state here
        
    }
    
    public func application(_ application: UIApplication,
                              viewControllerWithRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {
        if let firstIdentifier = identifierComponents.first,
           firstIdentifier == "net.relisten.RelistenNavigationController" {
            let artists = ArtistsViewController()
            let nav = RelistenNavigationController(rootViewController: artists)
            nav.tabBarItem = artists.tabBarItem
            rootNavigationController = nav
            return rootNavigationController
        }
        return nil
    }
}

// MARK: URL Handling
extension AppDelegate {
    func handleURL(url : URL) {
        // https://relisten.net/grateful-dead/1967/02/12/smokestack-lightning?source=87690
        
        LogDebug("Handling URL \(url)...")
        let parts = url.pathComponents
        
        let artistsVc = rootNavigationController.viewControllers.first! as! ArtistsViewController
        var vcs: [UIViewController] = [ artistsVc ]
        
        guard let artists = artistsVc.latestData else {
            LogWarn("Couldn't get the artists from the artists view controller. Failing to handle URL \(url)")
            return
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
        
        LogDebug("Handled URL \(url.absoluteString)")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            self.handleURL(url: url)
        }
        return true
    }
}
