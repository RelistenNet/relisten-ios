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

let PersistentCacheDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                                        FileManager.SearchPathDomainMask.userDomainMask,
                                                                                        true).first! + "/")

public class RelistenCacher : ResponseTransformer {
    static let cacheName = "RelistenCache"
    
    let diskCacheConfig = DiskConfig(
        name: RelistenCacher.cacheName,
        
        expiry: .never,
        
        // 100 MB max data cache
        maxSize: 1024 * 1024 * 100,
        
        directory: PersistentCacheDirectory
    )
    
    let memoryCacheConfig = MemoryConfig(
        expiry: .never,
        countLimit: 200,
        
        // 25MB
        totalCostLimit: 1024 * 1024 * 25
    )
    
    public let showBackingCache: Storage<ShowWithSources>
    public let artistBackingCache: Storage<ArtistWithCounts>

    public static let shared = RelistenCacher()
    
    // private to allow for only one instance
    private init() {
        showBackingCache = try! Storage(
            diskConfig: diskCacheConfig,
            memoryConfig: memoryCacheConfig,
            transformer: TransformerFactory.forCodable(ofType: ShowWithSources.self)
        )

        artistBackingCache = try! Storage(
            diskConfig: diskCacheConfig,
            memoryConfig: memoryCacheConfig,
            transformer: TransformerFactory.forCodable(ofType: ArtistWithCounts.self)
        )
    }
    
    public func process(_ response: Response) -> Response {
        switch response {
        case .success(let entity):
            if let show: ShowWithSources = entity.typedContent() {
                // caching
                showBackingCache.async.setObject(show, forKey: show.uuid.uuidString) { (res) in
                    switch res {
                    case .error(let err):
                        assertionFailure(err.localizedDescription)
                    default:
                        return
                    }
                }
            }
            else if let artists: [ArtistWithCounts] = entity.typedContent() {
                // caching
                for artist in artists {
                    artistBackingCache.async.setObject(artist, forKey: artist.uuid.uuidString) { (res) in
                        switch res {
                        case .error(let err):
                            assertionFailure(err.localizedDescription)
                        default:
                            return
                        }
                    }
                }
            }
            
            return response
        default:
            return response
        }
    }
}

class RelistenJsonCache : EntityCache {
    typealias Key = String
    
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
    
    let backingCache: Storage<Entity<Any>>
    
    init() {
        backingCache = try! Storage(
            diskConfig: diskCacheConfig,
            memoryConfig: memoryCacheConfig,
            transformer: TransformerFactory.forCodable(ofType: Entity<Any>.self)
        )
    }
    
    func key(for resource: Resource) -> String? {
        return resource.url.absoluteString
    }
    
    func readEntity(forKey key: String) -> Entity<Any>? {
        do {
            let val = try backingCache.object(forKey: key)
            
            print("[cache] readEntity(forKey \(key)) = *snip*")//\(String(describing: val))")
            
            return val
        }
        catch {
            if let sError = error as? StorageError {
                if sError != StorageError.notFound {
                    print(error)
                }
            }
            
            return nil
        }
    }
    
    func writeEntity(_ entity: Entity<Any>, forKey key: String) {
        print("[cache] writeEntity(forKey \(key)) = *snip*")//\(entity)")
        
        // lets not cache non-json responses for now
        guard entity.content is SwJSON else {
            print("trying to cache non json response!")
            return
        }
        
        do {
            try backingCache.setObject(entity, forKey: key)
        }
        catch {
            print("error caching entity!")
        }
    }
    
    func removeEntity(forKey key: String) {
        print("[cache] removeEntity(forKey \(key))")
        
        do {
            try backingCache.removeObject(forKey: key)
        }
        catch {
            print("error removing entity!")
        }
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
    
    /*
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
    */
}
