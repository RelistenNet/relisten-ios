//
//  Events.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Observable

public class Event<T> {
    public typealias EventHandler = (T) -> ()
    
    public func raise(_ data: T) {
        observers.values.forEach { $0(data) }
    }
    
    private var observers: [Int: EventHandler] = [:]
    private var uniqueID = (0...).makeIterator()
    
    public func addHandler(_ observer: @escaping EventHandler) -> Disposable {
        guard let id = uniqueID.next() else { fatalError("There should always be a next unique id") }
        
        observers[id] = observer
        
        let disposable = Disposable { [weak self] in
            self?.observers[id] = nil
        }
        
        return disposable
    }
    
    public func removeAllObservers() {
        observers.removeAll()
    }
}
