//
//  UserFeedback.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import PinpointKit

public class UserFeedback : ScreenshotDetectorDelegate {
    static public let shared = UserFeedback()
    
    let pinpointKit : PinpointKit
    var screenshotDetector : ScreenshotDetector?
    
    public init() {
        pinpointKit = PinpointKit(feedbackRecipients: ["feedback@relisten.net"])
    }
    
    public func setup() {
        screenshotDetector = ScreenshotDetector(delegate: self)
    }
    
    public func requestUserFeedback(from viewController : UIViewController? = nil) {
        pinpointKit.show(from: viewController ?? RelistenApp.sharedApp.delegate.rootNavigationController)
    }
    
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didDetect screenshot: UIImage) {
        
    }
    
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didFailWith error: ScreenshotDetector.Error) {
        
    }
}
