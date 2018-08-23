//
//  Wormholy.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
#if DEBUG
import Wormholy
#endif

public func setupWormholy() {
#if DEBUG
    Wormholy.shakeEnabled = false
    WormholyGestureMonitor.shared.setup()
#endif
}

class WormholyGestureMonitor {
    static let shared = WormholyGestureMonitor()
    
    fileprivate func setup() {
        let recognizer = UITapGestureRecognizer(target:self, action: #selector(wormholyGestureHappened(_:)))
        recognizer.numberOfTapsRequired = 3
        recognizer.numberOfTouchesRequired = 2
        RelistenApp.sharedApp.delegate.rootNavigationController?.navigationBar.addGestureRecognizer(recognizer)
    }
    
    @objc public func wormholyGestureHappened(_ recognizer : UITapGestureRecognizer) {
        if recognizer.state == .ended {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "wormholy_fire"), object: nil)
        }
    }
}
