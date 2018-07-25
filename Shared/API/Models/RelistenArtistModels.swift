//
//  RelistenArtistModels.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/22/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

public class SlimArtist : RelistenObject, Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
    
    public static func == (lhs: SlimArtist, rhs: SlimArtist) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let musicbrainz_id: String
    public let featured: Int
    
    public let name: String
    public let slug: String
    
    // This is a hack for now to make Phish sort descending. We should consider adding this to the API
    public var shouldSortYearsDescending : Bool { get {
        guard let apiValue = originalJSON["sort_descending"].bool else {
            return slug == "phish"
        }
        return apiValue
        }}
    
    public required init(json: JSON) throws {
        musicbrainz_id = try json["musicbrainz_id"].string.required()
        featured = try json["featured"].int.required()
        
        name = try json["name"].string.required()
        slug = try json["slug"].string.required()
        
        try super.init(json: json)
    }
}

public class SlimArtistWithFeatures : SlimArtist {
    public let features: Features
    
    public required init(json: JSON) throws {
        features = try Features(json: json["features"])
        
        try super.init(json: json)
    }
}

public class Artist : SlimArtistWithFeatures {
    public let upstream_sources: [ArtistUpstreamSource]
    
    public required init(json: JSON) throws {
        upstream_sources = try json["upstream_sources"].arrayValue.map({ return try ArtistUpstreamSource(json: $0) })
        
        try super.init(json: json)
    }
}

public class ArtistWithCounts : Artist {
    public let show_count: Int
    public let source_count: Int
    
    public required init(json: JSON) throws {
        show_count = try json["show_count"].int.required()
        source_count = try json["source_count"].int.required()
        
        try super.init(json: json)
    }
}

public class SlimArtistUpstreamSource {
    public let upstream_source_id: Int
    public let upstream_identifier: String?
    
    public required init(json: JSON) throws {
        upstream_source_id = try json["upstream_source_id"].int.required()
        upstream_identifier = json["upstream_identifier"].string
    }
}

public class ArtistUpstreamSource : SlimArtistUpstreamSource {
    public let artist_id: Int
    public let upstream_source: UpstreamSource?
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        upstream_source = !json["upstream_source"].isEmpty ? try UpstreamSource(json: json["upstream_source"]) : nil
        
        try super.init(json: json)
    }
}

public struct UpstreamSource {
    public let id : Int
    public let name : String
    public let url : String
    public let description : String
    public let credit_line : String
    
    public init(json: JSON) throws {
        id = try json["id"].int.required()
        name = try json["name"].string.required()
        url = try json["url"].string.required()
        description = try json["description"].string.required()
        credit_line = try json["credit_line"].string.required()
    }
}
