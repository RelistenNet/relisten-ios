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
    
    public func objectAtIndexIfInBounds(_ index: Int) -> Array.Element? {
        if index >= 0, index < self.count {
            return self[index]
        }
        return nil
    }
}

public func ArrayNoNils<T>(_ values: T?...) -> [T] {
    return values.filter({ $0 != nil }) as! [T]
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
