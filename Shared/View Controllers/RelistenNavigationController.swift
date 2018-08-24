//
//  RelistenNavigationController.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class RelistenNavigationController : ASNavigationController {
    open override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            UserFeedback.shared.requestUserFeedback(from: self)
        }
    }
}
