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
import Observable

let PersistentCacheDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                                        FileManager.SearchPathDomainMask.userDomainMask,
                                                                                        true).first! + "/")

protocol RelistenCache : EntityCache {
    var backingCache: AnyStorageAware<Entity<Any>> {get}
}

extension RelistenCache {
    func key(for resource: Resource) -> String? {
        return resource.url.absoluteString
    }
    
    func readEntity(forKey key: String) -> Entity<Any>? {
        do {
            let val = try backingCache.object(forKey: key)
            
            //LogDebug("[cache] readEntity(forKey \(key)) = *snip*")//\(String(describing: val))")
            
            return val
        }
        catch {
            if let sError = error as? StorageError {
                if sError != StorageError.notFound {
                    LogWarn("Error reading from the cache: \(error)")
                }
            }
            
            return nil
        }
    }
    
    func writeEntity(_ entity: Entity<Any>, forKey key: String) {
        //LogDebug("[cache] writeEntity(forKey \(key)) = *snip*")//\(entity)")
        
        // lets not cache non-json responses for now
        guard entity.content is SwJSON else {
            LogWarn("trying to cache non json response!")
            return
        }
        
        do {
            try backingCache.setObject(entity, forKey: key)
        }
        catch {
            LogWarn("error caching entity! \(error)")
        }
    }
    
    func removeEntity(forKey key: String) {
        //LogDebug("[cache] removeEntity(forKey \(key))")
        
        do {
            try backingCache.removeObject(forKey: key)
        }
        catch {
            LogWarn("error removing entity! \(error)")
        }
    }
}

class RelistenJsonCache : RelistenCache {
    static let cacheName = "RelistenApiCache"
    
    let diskCacheConfig = DiskConfig(
        name: RelistenJsonCache.cacheName,
        
        expiry: .never,
        
        // 100 MB max data cache
        maxSize: 1024 * 1024 * 100,
        
        directory: PersistentCacheDirectory
    )
    
    let memoryCacheConfig = MemoryConfig(
        expiry: .never,
        countLimit: 100,
        
        // 4MB
        totalCostLimit: 1024 * 1024 * 4
    )
    
    let backingCache: AnyStorageAware<Entity<Any>>
    
    init() {
        backingCache = try! AnyStorageAware(Storage(
            diskConfig: diskCacheConfig,
            memoryConfig: memoryCacheConfig,
            transformer: TransformerFactory.forCodable(ofType: Entity<Any>.self))
        )
    }
}

enum EntityCodableError: Error {
    case contentNotSwJSON
}

extension Entity : Codable {
    enum CodingKeys: String, CodingKey
    {
        case content
        case charset
        case headers
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(
            content: SwJSON(try values.decode(Data.self, forKey: .content)) as! ContentType,
            charset: try values.decode(String.self, forKey: .charset),
            headers: try values.decode(Dictionary.self, forKey: .headers),
            timestamp: try values.decode(TimeInterval.self, forKey: .timestamp)
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        guard let json = content as? SwJSON else {
            throw EntityCodableError.contentNotSwJSON
        }

        try container.encode(json.rawData(), forKey: .content)
        try container.encode(charset, forKey: .charset)
        try container.encode(headers, forKey: .headers)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
