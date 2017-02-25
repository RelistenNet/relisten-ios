//
//  RelistenModelCachable.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Cache

extension RelistenObject : Cachable {
    public typealias CacheType = RelistenObject
    
    public static func decode(_ data: Data) -> RelistenObject? {
        do {
            return try self.init(json: SwJSON(data: data))
        }
        catch {
            print("whoa. invalid item in the cache?!")
            return nil
        }
    }
    
    public func encode() -> Data? {
        do {
            return try self.toData()
        }
        catch {
            print("whoa. unable to cache item!?")
            return nil
        }
    }
}
