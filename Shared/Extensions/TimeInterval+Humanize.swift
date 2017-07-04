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

public extension TimeInterval {
    public func humanize() -> String {
        return TimeIntervalHumanizeFormatter.string(from: self)!
    }
}
