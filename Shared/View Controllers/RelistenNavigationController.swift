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
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.restorationIdentifier = "net.relisten.RelistenNavigationController"
    }
    
    //MARK: State Restoration
//    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
//        let vc = RelistenNavigationController(nibName: nil, bundle: nil)
//        return vc
//    }
    
    //MARK: Wormholy
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, RelistenApp.sharedApp.shakeToReportBugEnabled.value {
            UserFeedback.shared.requestUserFeedback(from: self)
        }
    }
}
