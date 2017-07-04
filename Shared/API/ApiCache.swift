//
//  ApiCache.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Siesta
import Cache

class RelistenJsonCache : EntityCache {
    typealias Key = String
    
    static let cacheName = "RelistenApiCache"
    
    let cacheConfig = Config(
        frontKind: .memory,
        backKind: .disk,
        expiry: .never,
        
        // 100 MB max data cache
        maxSize: 1024 * 1024 * 100,
        
        // max objects to hold in cache at once
        maxObjects: 100,
        
        cacheDirectory: NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                            FileManager.SearchPathDomainMask.userDomainMask,
                                                            true).first! + "/" + cacheName
    )
    
    let backingCache: SyncCache<Entity<Any>>
    
    init() {
        let cache = Cache<Entity<Any>>(name: RelistenJsonCache.cacheName, config: self.cacheConfig)
        backingCache = SyncCache(cache)
    }
    
    func key(for resource: Resource) -> String? {
        return resource.url.absoluteString
    }
    
    func readEntity(forKey key: String) -> Entity<Any>? {
        let val = backingCache.object(key)
        
        print("[cache] readEntity(forKey \(key)) = *snip*")//\(String(describing: val))")
        
        return val
    }
    
    func writeEntity(_ entity: Entity<Any>, forKey key: String) {
        print("[cache] writeEntity(forKey \(key)) = *snip*")//\(entity)")
        
        // lets not cache non-json responses for now
        guard entity.content is SwJSON else {
            print("trying to cache non json response!")
            return
        }
        
        backingCache.add(key, object: entity)
    }
    
    func removeEntity(forKey key: String) {
        print("[cache] removeEntity(forKey \(key))")
        
        backingCache.remove(key)
    }
}

extension Entity : Cachable {
    public typealias CacheType = Entity
    
    public static func decode(_ data: Data) -> Entity<ContentType>? {
        let json = SwJSON(data: data)
        
        return Entity<ContentType>(
            content: SwJSON(json["content"].object) as! ContentType,
            charset: json["charset"].string,
            headers: (json["headers"].dictionaryObject as? Dictionary<String, String>) ?? [:],
            timestamp: json["timestamp"].double as TimeInterval?
        )
    }
    
    public func encode() -> Data? {
        guard let json = content as? SwJSON else {
            return nil
        }
        
        let j: SwJSON = [
            "charset": charset as Any,
            "headers": headers,
            "timestamp": timestamp,
            "content": json.object
        ]
        
        return try! j.rawData()
    }
}
