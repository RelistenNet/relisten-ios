//
//  RelistenCacher.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/21/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

import Cache
import Siesta
import Observable
import Crashlytics

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
    
    public let artists = Observable<[String: ArtistWithCounts]>([:])

    public static func artistFromCache(forId artist_id: Int) -> ArtistWithCounts? {
        guard let a = RelistenDb.shared.artist(byId: artist_id) else {
            if let a = shared.artists.value.filter({ $1.id == artist_id }).first?.value {
                RelistenDb.shared.cache(artists: [a])
                return a
            }
            
            LogError("Error fetching from cache artist with Id=\(artist_id)")
            
            return nil
        }
        
        return a
    }
    
    public static func artistFromCache(forUUID artist_uuid: UUID) -> ArtistWithCounts? {
        guard let a = RelistenDb.shared.artist(byUUID: artist_uuid) else {
            // attempt to migrate from the old Cache based cache
            do {
                let a = try shared.artistBackingCache.object(forKey: artist_uuid.uuidString)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    RelistenDb.shared.cache(artists: [a])
                }
                
                return a
            } catch {
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["artist_uuid": artist_uuid])
                LogError("Error fetching from cache artist with UUID=\(artist_uuid): \(error)")
            }
            
            return nil
        }
        
        return a
    }
    
    public static func showFromCache(forUUID show_uuid: UUID) -> ShowWithSources? {
        guard let s = RelistenDb.shared.show(byUUID: show_uuid) else {
            // attempt to migrate from the old Cache based cache
            do {
                let s = try shared.showBackingCache.object(forKey: show_uuid.uuidString)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    RelistenDb.shared.cache(show: s)
                }
                
                return s
            } catch {
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["show_uuid": show_uuid])
                LogError("Error fetching from cache show with UUID=\(show_uuid): \(error)")
            }
            
            return nil
        }
        
        return s
    }
    
    public func process(_ response: Response) -> Response {
        switch response {
        case .success(let entity):
            if let show: ShowWithSources = entity.typedContent() {
                DispatchQueue.global(qos: .userInitiated).async {
                    RelistenDb.shared.cache(show: show)
                }

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
                DispatchQueue.global(qos: .userInitiated).async {
                    RelistenDb.shared.cache(artists: artists)
                }
                    
                for artist in artists {
                    self.artistBackingCache.async.setObject(artist, forKey: artist.uuid.uuidString) { (res) in
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

