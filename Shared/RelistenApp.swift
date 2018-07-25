//
//  RelistenApp.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/25/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit

public protocol RelistenAppDelegate {
    var rootNavigationController: ASNavigationController! { get }
    func setupAppearance(_ viewController: UINavigationController?)
}

public class RelistenApp {
    public static let sharedApp = RelistenApp(delegate: RelistenDummyAppDelegate())
    
    public var delegate : RelistenAppDelegate
    
    public init(delegate: RelistenAppDelegate) {
        self.delegate = delegate
    }
}

public class RelistenDummyAppDelegate : RelistenAppDelegate {
    public var rootNavigationController: ASNavigationController! {
        get {
            fatalError("An application delegate hasn't been set yet!")
        }
    }
    
    public func setupAppearance(_ viewController: UINavigationController? = nil) {
        fatalError("An application delegate hasn't been set yet!")
    }
}
