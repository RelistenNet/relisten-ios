//
//  RealmNotificationDisposables.swift
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
        return Disposable { [weak self] in
            guard let self = self else { return }
            self.invalidate()
        }
    }
    
    public func dispose(to disposal: inout Disposal) {
        disposable().add(to: &disposal)
    }
}
