//
//  RealmExtensions.swift
//  RelistenShared
//
//  Created by Alec Gorge on 7/29/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import RealmSwift
import Observable

extension NotificationToken {
    public func disposable() -> Disposable {
        // (Farkas) According to the Realm headers, the NotificationToken must be retained for as long as we want updates to continue to be sent.
        // We're pulling some shenanigans here and having the disposable object retain the token with a non-weak self reference.
        // This keeps the token around until it is disposed, and it shouldn't cause a circular reference because the token doesn't retain the disposable object.
        // If you're reading this comment that means my assumption was wrong. Sorry!
        return Disposable {
            self.invalidate()
        }
    }
    
    public func dispose(to disposal: inout Disposal) {
        disposable().add(to: &disposal)
    }
}

public extension Results {
    func array(toIndex index: Int = -1) -> [Element] {
        if index == -1 {
            return Array(self)
        } else {
            var results : [Element] = []
            let maxResults = Swift.min(index, self.count)
            for i in (0..<maxResults) {
                results.append(self[i])
            }
            return results
        }
    }
    
    func observeWithValue(_ block: @escaping (Results<Element>, RealmCollectionChange<Results<Element>>) -> Void) -> NotificationToken {
        return self.observe { changes in
            block(self, changes)
        }
    }
}
