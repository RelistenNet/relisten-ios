//
//  RelistenSourceModels.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

public class Source : RelistenObject {
    public let artist_id: Int
    
    public let show_id: Int
    public let show: Show?
    
    // only for per-source venues
    public let venue_id: Int?
    public let venue: Venue?
    
    public let display_date: String
    
    public let is_soundboard: Bool
    public let is_remaster: Bool
    public let has_jamcharts: Bool
    
    public let avg_rating: Float
    public let num_reviews: Int
    public let num_ratings: Int?
    public let avg_rating_weighted: Float
    
    public let duration: TimeInterval?
    
    public let upstream_identifier: String
    
    public let description: String?
    public let taper_notes: String?
    public let source: String?
    public let taper: String?
    public let transferrer: String?
    public let lineage: String?
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        show_id = try json["show_id"].int.required()
        show = json["show"].isEmpty ? nil : try Show(json: json["show"])
        
        venue_id = json["venue_id"].int
        venue = json["venue"].isEmpty ? nil : try Venue(json: json["venue"])
        
        display_date = try json["display_date"].string.required()
        
        is_soundboard = try json["is_soundboard"].bool.required()
        is_remaster = try json["is_remaster"].bool.required()
        has_jamcharts = try json["has_jamcharts"].bool.required()
        
        avg_rating = try json["avg_rating"].float.required()
        num_reviews = try json["num_reviews"].int.required()
        num_ratings = json["num_ratings"].int
        avg_rating_weighted = try json["avg_rating_weighted"].float.required()
        
        duration = json["duration"].double as TimeInterval?
        
        upstream_identifier = try json["upstream_identifier"].string.required()
        
        description = json["description"].string
        taper_notes = json["taper_notes"].string
        source = json["source"].string
        taper = json["taper"].string
        transferrer = json["transferrer"].string
        lineage = json["lineage"].string

        try super.init(json: json)
    }
}

public class SourceFull : Source {
    public let reviews: [SourceReview]
    public let sets: [SourceSet]
    
    public required init(json: JSON) throws {
        reviews = try json["reviews"].arrayValue.map(SourceReview.init)
        sets = try json["sets"].arrayValue.map(SourceSet.init)
        
        try super.init(json: json)
    }
}

public class SourceSet : RelistenObject {
    public let source_id: Int
    
    public let index: Int
    public let is_encore: Bool
    public let name: String
    
    public let tracks: [SourceTrack]
    
    public required init(json: JSON) throws {
        source_id = try json["source_id"].int.required()
        
        index = try json["index"].int.required()
        is_encore = try json["is_encore"].bool.required()
        name = try json["name"].string.required()
        
        tracks = try json["tracks"].arrayValue.map(SourceTrack.init)
        
        try super.init(json: json)
    }
}

public class SourceTrack : RelistenObject {
    public let source_id: Int
    public let source_set_id: Int
    
    public let track_position: Int
    public let duration: TimeInterval?
    
    public let title: String
    public let slug: String
    
    public let mp3_url: URL
    public let md5: String?
    
    public required init(json: JSON) throws {
        source_id = try json["source_id"].int.required()
        source_set_id = try json["source_set_id"].int.required()
        
        track_position = try json["track_position"].int.required()
        duration = json["duration"].double as TimeInterval?
        
        title = try json["title"].string.required()
        slug = try json["slug"].string.required()
        
        mp3_url = try json["mp3_url"].toURL.required()
        md5 = json["md5"].string
        
        try super.init(json: json)
    }
}

public class SourceReview : RelistenObject {
    public let source_id: Int
    
    // out of 10
    public let rating: Int?
    
    public let title: String?
    public let review: String
    public let author: String?
    
    public required init(json: JSON) throws {
        source_id = try json["source_id"].int.required()
        
        rating = json["rating"].int
        
        title = json["title"].string
        review = try json["review"].string.required()
        author = json["author"].string
        
        try super.init(json: json)
    }
}
