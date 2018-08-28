//
//  UInt64+HumanizeBytes.swift
//  Relisten
//
//  Created by Alec Gorge on 5/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

extension UInt64 {
    public func humanizeBytes() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        bcf.isAdaptive = true
        
        return bcf.string(fromByteCount: Int64(self))
    }
}
