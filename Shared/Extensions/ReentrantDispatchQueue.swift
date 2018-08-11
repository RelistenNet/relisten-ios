//
//  DispatchQueue.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/27/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

// This class wraps a DispatchQueue and allows for sync calls to itself without deadlocking.
// Note: blocks that are async'ed while currently on the queue will run immediately rather than enqueuing
public class ReentrantDispatchQueue {
    static public let main : ReentrantDispatchQueue = ReentrantDispatchQueue.init(withMainQueue: true)
    
    private let queueKey = DispatchSpecificKey<Int>()
    private let queue : DispatchQueue
    
    public init(queue: DispatchQueue) {
        self.queue = queue
        self.queue.setSpecific(key: queueKey, value: 1)
    }
    
    public convenience init(_ label: String) {
        let q = DispatchQueue(label: label)
        self.init(queue: q)
    }
    
    public convenience init(withMainQueue: Bool) {
        if withMainQueue {
            self.init(queue: DispatchQueue.main)
        } else {
            self.init("net.relisten.reentrantQueue")
        }
    }
    
    public convenience init(label: String, qos: DispatchQoS = .default, attributes: DispatchQueue.Attributes = DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) {
        let q = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
        self.init(queue: q)
    }

    public func sync(execute block: () -> Swift.Void) {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            block()
        } else {
            self.queue.sync(execute: block)
        }
    }
    
    public func async(_ block: @escaping () -> Swift.Void) {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            block()
        } else {
            self.queue.async(execute: block)
        }
    }
    
    public func assertQueue() {
        dispatchPrecondition(condition: .onQueue(self.queue))
    }
}

public func performOnMainQueueSync(_ block: () -> Swift.Void) {
    ReentrantDispatchQueue.main.sync(execute: block)
}
