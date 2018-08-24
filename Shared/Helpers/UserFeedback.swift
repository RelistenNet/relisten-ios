//
//  UserFeedback.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import PinpointKit
import CWStatusBarNotification

public class UserFeedback : ScreenshotDetectorDelegate {
    static public let shared = UserFeedback()
    
    let pinpointKit : PinpointKit
    var screenshotDetector : ScreenshotDetector?
    var currentNotification : CWStatusBarNotification?
    
    public init() {
        pinpointKit = PinpointKit(feedbackRecipients: ["feedback@relisten.net"])
    }
    
    public func setup() {
        screenshotDetector = ScreenshotDetector(delegate: self)
    }
    
    public func presentFeedbackView(from vc: UIViewController? = nil, screenshot : UIImage? = nil) {
        guard let viewController = vc ?? RelistenApp.sharedApp.delegate.rootNavigationController else { return }
        currentNotification?.dismiss()
        
        if let screenshot = screenshot {
            pinpointKit.show(from: viewController, screenshot: screenshot)
        } else {
            pinpointKit.show(from: viewController)
        }
    }
    
    public func requestUserFeedback(from vc : UIViewController? = nil, screenshot : UIImage? = nil) {
        currentNotification?.dismiss()
        
        let notification = CWStatusBarNotification()
        notification.notificationTappedBlock = {
            self.presentFeedbackView(screenshot: screenshot)
        }
        notification.notificationStyle = .navigationBarNotification
        notification.notificationLabelBackgroundColor = AppColors.highlight
        
        currentNotification = notification
        currentNotification?.display(withMessage: "Tap here to report a bug", forDuration: 3.0)
    }
    
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didDetect screenshot: UIImage) {
        requestUserFeedback(screenshot: screenshot)
    }
    
    public func screenshotDetector(_ screenshotDetector: ScreenshotDetector, didFailWith error: ScreenshotDetector.Error) {
        
    }
}
