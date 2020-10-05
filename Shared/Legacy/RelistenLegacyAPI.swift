//
//  RelistenLegacyAPI.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import Siesta
import SwiftyJSON
import Cache

public class RelistenLegacyAPI {
    private let service = Service(baseURL:"http://iguana.app.alecgorge.com/api")
    
    public init() {
        #if DEBUG
        // Bare-bones logging of which network calls Siesta makes:
        SiestaLog.Category.enabled = [] // [.network]
        
        // For more info about how Siesta decides whether to make a network call,
        // and when it broadcasts state updates to the app:
        //LogCategory.enabled = LogCategory.common
        
        // For the gory details of what Siesta’s up to:
        //LogCategory.enabled = LogCategory.detailed
        #endif
        
        // Global configuration
        
        service.configure {
            $0.expirationTime = 60 * 60 * 24 * 365 * 10 as TimeInterval
            
            $0.pipeline[.parsing].add(SwiftyJSONTransformer, contentTypes: ["*/json"])
            $0.pipeline[.parsing].cacheUsing(RelistenLegacyJSONCache())
            
            //$0.pipeline[.parsing].cacheUsing(RelistenJsonCache())
        }
        
        // Resource-specific configuration
        
        service.configureTransformer("/artists/*") {
            return LegacyArtist(json: ($0.content as JSON)["data"])
        }
        
        service.configureTransformer("/artists/*/shows/*") {
            return LegacyShowWithTracks(json: ($0.content as JSON)["data"])
        }
    }
    
    public func artist(_ slug: String) -> Resource {
        return service
            .resource("/artists")
            .child(slug)
    }
    
    public func fullShow(byArtist slug: String, showID: Int) -> Resource {
        return artist(slug)
            .child("shows")
            .child(String(showID))
    }
}

class RelistenLegacyJSONCache : RelistenCache {
    let backingCache: AnyStorageAware<String, Entity<Any>>
    
    let memoryCacheConfig = MemoryConfig(
        expiry: .never,
        countLimit: 1000,
        
        // 4MB
        totalCostLimit: 1024 * 1024 * 4
    )
    
    public init() {
        backingCache = AnyStorageAware(MemoryStorage(config: memoryCacheConfig))
    }
}
