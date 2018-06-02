//
//  Events.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Observable

private var EventUniqueID = (0...).makeIterator()
public let EventHandlerQueue = DispatchQueue(label: "eventDispatchingQueue", attributes: .concurrent)

public class Event<T> {
    
    public typealias EventHandler = (T) -> ()
    
    public func raise(_ data: T) {
        queue.sync {
            observers.values.forEach { cb in EventHandlerQueue.async { cb(data) } }
        }
    }
    
    private let queue: DispatchQueue

    public init() {
        queue = DispatchQueue(label: "event queue #\(EventUniqueID.next()!)", attributes: .concurrent)
    }
    
    private var observers: [Int: EventHandler] = [:]
    private var uniqueID = (0...).makeIterator()
    
    public func addHandler(_ observer: @escaping EventHandler) -> Disposable {
        guard let id = uniqueID.next() else { fatalError("There should always be a next unique id") }
        
        queue.async(flags: .barrier) {
            self.observers[id] = observer
        }
        
        let disposable = Disposable { [weak self] in
            self?.observers[id] = nil
        }
        
        return disposable
    }
    
    public func removeAllObservers() {
        observers.removeAll()
    }
}
