//
//  TimeInterval+Humanize.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

let TimeIntervalHumanizeFormatter = { () -> DateComponentsFormatter in
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [ .hour, .minute, .second ]
    formatter.zeroFormattingBehavior = [ .dropLeading, .pad ]
    return formatter
}()

let TimeIntervalHumanizeShortFormatter = { () -> DateComponentsFormatter in
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [ .minute, .second ]
    formatter.zeroFormattingBehavior = [ .pad ]
    return formatter
}()

public extension TimeInterval {
    public func humanize() -> String {
        if(self < 60) {
            return TimeIntervalHumanizeShortFormatter.string(from: self)!
        }
        
        return TimeIntervalHumanizeFormatter.string(from: self)!
    }
}
