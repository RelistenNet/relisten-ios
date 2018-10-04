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
    override public var preferredStatusBarStyle: UIStatusBarStyle { get { return .lightContent } }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake, RelistenApp.sharedApp.shakeToReportBugEnabled.value {
            UserFeedback.shared.requestUserFeedback(from: self)
        }
    }
}
