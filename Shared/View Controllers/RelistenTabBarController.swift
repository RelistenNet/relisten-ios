//
//  RelistenTabBarController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/19/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import UIKit

public enum RelistenTabs : Int, RawRepresentable {
    case artistsOrPhish = 1000
    case favorites = 1001
    case downloads = 1002
    case recent = 1003
    case live = 1004
}

public class RelistenTabBarController : UITabBarController {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(_ firstTabViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        
        let faves = MyLibraryTabViewController()
        let dl = DownloadedTabViewController()
        let rec = RecentlyPlayedTabViewController()
        
        setViewControllers([
            firstTabViewController,
            wrapInNavigation(faves, "My Favorites", .favorites, UIImage(named: "toolbar_heart")),
            wrapInNavigation(rec, "My Recents", .recent, UIImage(named: "toolbar_history")),
            wrapInNavigation(dl, "Downloaded", .downloads, UIImage(named: "toolbar_offline")),
        ], animated: false)
    }
    
    func wrapInNavigation(_ viewController: UIViewController, _ title: String, _ tab: RelistenTabs, _ image: UIImage? = nil) -> RelistenNavigationController {
        viewController.tabBarItem = UITabBarItem(title: title, image: image, tag: tab.rawValue)

        let nav = RelistenNavigationController(rootViewController: viewController)
        nav.tabBarItem = viewController.tabBarItem
        
        return nav
    }
}
