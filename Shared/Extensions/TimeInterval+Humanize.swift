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

// DateComponentsFormatter claims to be thread safe, but without this serial queue for formatting there are
//  occasional races where dates will get formatted with a leading '0'
let formatQueue : DispatchQueue = DispatchQueue(label: "live.relisten.ios.dateFormatQueue")

public extension TimeInterval {
    func humanize() -> String {
        var returnValue = ""
        formatQueue.sync {
            if(self < 60) {
                returnValue = TimeIntervalHumanizeShortFormatter.string(from: self)!
            }
            
            returnValue = TimeIntervalHumanizeFormatter.string(from: self)!
        }
        return returnValue
    }
}
