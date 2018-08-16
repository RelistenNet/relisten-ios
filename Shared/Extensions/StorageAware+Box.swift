//
//  StorageAware+Box.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Cache

// (farkas) Thanks to https://medium.com/@vhart/a-swift-walk-through-type-erasure-12fbe3827a10 for explaining this. I would have never figured it out on my own.

private class BaseStorageAware<T> : StorageAware {
    init() {
        guard type(of: self) != BaseStorageAware.self
            else { fatalError("do not initialize this abstract class directly") }
    }
    
    func entry(forKey key: String) throws -> Entry<T> {
        fatalError("Abstract class. Subclass must override")
    }
    
    func removeObject(forKey key: String) throws {
        fatalError("Abstract class. Subclass must override")
    }
    
    func setObject(_ object: T, forKey key: String, expiry: Expiry?) throws {
        fatalError("Abstract class. Subclass must override")
    }
    
    func removeAll() throws {
        fatalError("Abstract class. Subclass must override")
    }
    
    func removeExpiredObjects() throws {
        fatalError("Abstract class. Subclass must override")
    }
}

private class StorageAwareBox<D: StorageAware>: BaseStorageAware<D.T> {
    private let storage: D
    
    init (concreteStorage: D) {
        self.storage = concreteStorage
    }
    
    override func entry(forKey key: String) throws -> Entry<T> {
        return try storage.entry(forKey: key)
    }
    
    override func removeObject(forKey key: String) throws {
        try storage.removeObject(forKey: key)
    }
    
    override func setObject(_ object: T, forKey key: String, expiry: Expiry?) throws {
        try storage.setObject(object, forKey: key, expiry: expiry)
    }
    
    override func removeAll() throws {
        try storage.removeAll()
    }
    
    override func removeExpiredObjects() throws {
        try storage.removeExpiredObjects()
    }
}

public class AnyStorageAware<T>: StorageAware {
    private let storageAwareBox : BaseStorageAware<T>
    
    public init<Concrete: StorageAware>(_ storage: Concrete)
        where Concrete.T == T {
            let box = StorageAwareBox(concreteStorage: storage)
            self.storageAwareBox = box
    }
    
    public func entry(forKey key: String) throws -> Entry<T> {
        return try storageAwareBox.entry(forKey: key)
    }
    
    public func removeObject(forKey key: String) throws {
        try storageAwareBox.removeObject(forKey: key)
    }
    
    public func setObject(_ object: T, forKey key: String, expiry: Expiry? = nil) throws {
        try storageAwareBox.setObject(object, forKey: key, expiry: expiry)
    }
    
    public func removeAll() throws {
        try storageAwareBox.removeAll()
    }
    
    public func removeExpiredObjects() throws {
        try storageAwareBox.removeExpiredObjects()
    }
}
