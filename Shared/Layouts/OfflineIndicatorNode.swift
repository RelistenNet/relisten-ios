//
//  OfflineIndicatorNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import AsyncDisplayKit

public let OfflineIndicatorImage = UIImage(named: "download-complete")!
public let OfflineDownloadingIndicatorImage = UIImage(named: "download-active")!

public class OfflineIndicatorNode : ASImageNode {
    public override init() {
        super.init()
        
        image = OfflineIndicatorImage
        contentMode = .scaleAspectFit
        style.preferredSize = CGSize(width: 12, height: 12)
        automaticallyManagesSubnodes = true
    }
}

public class OfflineDownloadingIndicatorNode : ASImageNode {
    public override init() {
        super.init()
        
        image = OfflineDownloadingIndicatorImage
        contentMode = .scaleAspectFit
        style.preferredSize = CGSize(width: 12, height: 12)
        automaticallyManagesSubnodes = true
    }
    
    public func startAnimating() {
        DispatchQueue.main.async {
            self.view.alpha = 1.0
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           options: [UIViewAnimationOptions.autoreverse, UIViewAnimationOptions.repeat],
                           animations: {
                            self.view.alpha = 0.0
                           },
                           completion: nil)
        }
    }
    
    public func stopAnimating() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0, animations: {
                self.view.alpha = 1.0
            })
        }
    }
}
