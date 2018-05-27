//
//  MaxLengthArray.swift
//  Relisten
//
//  Created by Alec Gorge on 5/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public extension Array {
    @discardableResult public mutating func insertAtBeginning(_ element: Array.Element, ensuringMaxCapacity: Int) -> Array.Element? {
        if count >= ensuringMaxCapacity {
            return removeLast()
        }
        
        insert(element, at: 0)
        
        return nil
    }
}
