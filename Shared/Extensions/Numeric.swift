//
//  Numeric.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public extension Numeric {
    public func pluralize(_ single: String, _ multiple: String) -> String {
        if(self == 1) {
            return "\(self) \(single)"
        }
        
        return "\(self) \(multiple)"
    }
}

