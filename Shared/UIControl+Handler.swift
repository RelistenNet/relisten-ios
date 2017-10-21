//
//  UIControl+Handler.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

private var controlHandlerKey: Int8 = 0

/// A target that accepts action messages.
internal final class CocoaTarget<Value>: NSObject {
    private let action: (Value) -> ()
    
    internal init(_ action: @escaping (Value) -> ()) {
        self.action = action
    }
    
    @objc
    internal func sendNext(_ receiver: Any?) {
        action(receiver as! Value)
    }
}

extension UIControl {
    
    public func addHandler(for controlEvents: UIControlEvents, handler: @escaping (UIControl) -> ()) {
        if let oldTarget = objc_getAssociatedObject(self, &controlHandlerKey) as? CocoaTarget<UIControl> {
            self.removeTarget(oldTarget, action: #selector(oldTarget.sendNext), for: controlEvents)
        }
        
        let target = CocoaTarget<UIControl>(handler)
        objc_setAssociatedObject(self, &controlHandlerKey, target, .OBJC_ASSOCIATION_RETAIN)
        self.addTarget(target, action: #selector(target.sendNext), for: controlEvents)
    }
    
}
