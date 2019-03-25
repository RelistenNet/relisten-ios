//
//  RelistenTabBarController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/19/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import UIKit

public enum RelistenTabs : Int, RawRepresentable {
    case ArtistsOrPhish = 1000
    case Favorites = 1001
    case Downloads = 1002
    case Recent = 1003
    case Live = 1004
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
            wrapInNavigation(faves, "My Favorites", .Favorites),
            wrapInNavigation(rec, "My Recents", .Recent),
            wrapInNavigation(dl, "Downloaded", .Downloads),
        ], animated: false)
    }
    
    func wrapInNavigation(_ viewController: UIViewController, _ title: String, _ tab: RelistenTabs, _ image: UIImage? = nil) -> RelistenNavigationController {
        viewController.tabBarItem = UITabBarItem(title: title, image: image, tag: tab.rawValue)

        let nav = RelistenNavigationController(rootViewController: viewController)
        nav.tabBarItem = viewController.tabBarItem
        
        return nav
    }
}
