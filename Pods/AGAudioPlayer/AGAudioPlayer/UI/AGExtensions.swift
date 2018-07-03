//
//  AGExtensions.swift
//  AGAudioPlayer
//
//  Created by Alec Gorge on 1/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

extension TimeInterval {
    public func formatted() -> String {
        let seconds = Int(self.truncatingRemainder(dividingBy: 60));
        let minutes = Int((self / 60).truncatingRemainder(dividingBy: 60));
        let hours = Int(self / 3600);
        
        if(hours == 0) {
            return String(format: "%d:%02d", minutes, seconds);
        }
        
        return String(format: "%d:%02d:%02d", hours, minutes, seconds);
    }
}

extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    public func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier == 0 ? 1.0 : multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
