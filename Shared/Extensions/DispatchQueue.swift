//
//  DispatchQueue.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/27/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

class DispatchMainProperties {
    static let shared = DispatchMainProperties()
    let key : DispatchSpecificKey<()> = DispatchSpecificKey<()>()
    
    public var isMainQueue : Bool { get { return DispatchQueue.getSpecific(key: key) != nil } }
    
    public init() {
        DispatchQueue.main.setSpecific(key: key, value: ())
    }
}

func performOnMainQueueSync(_ block: () -> Swift.Void) {
    if DispatchMainProperties.shared.isMainQueue {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
}
