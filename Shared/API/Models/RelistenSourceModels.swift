//
//  RelistenSourceModels.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON
import SINQ

public enum FlacType : String {
    case NoFlac = "NoFlac"
    case Flac16Bit = "Flac16Bit"
    case Flac24Bit = "Flac24Bit"
    case NoPlayableFlac = "NoPlayableFlac"
}

public class SlimSource : RelistenObject, RelistenUUIDObject {
    public let uuid: UUID
    
    public let artist_id: Int
    
    // only for per-source venues
    public let venue_id: Int?
    public let venue: VenueWithShowCount?
    
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
    
    public required init(json: JSON) throws {
        uuid = try json["uuid"].uuid.required()
        
        artist_id = try json["artist_id"].int.required()
        
        venue_id = json["venue_id"].int
        venue = json["venue"].isEmpty ? nil : try VenueWithShowCount(json: json["venue"])
        
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
        
        try super.init(json: json)
    }
}

public class SlimSourceWithShowAndArtist : SlimSource {
    public let artist: Artist
    
    public let show_id: Int
    public let show: Show
    
    public required init(json: JSON) throws {
        artist = try Artist(json: json["artist"])

        show_id = try json["show_id"].int.required()
        show = try Show(json: json["show"])
        
        try super.init(json: json)
    }
}

enum FlacTypeError: Error {
    case invalid(attempted: String?)
}

public class Source : SlimSource {
    public let show_id: Int
    public let show: Show?
    
    public let description: String?
    public let taper_notes: String?
    public let source: String?
    public let taper: String?
    public let transferrer: String?
    public let lineage: String?
    
    public let flac_type: FlacType
    
    public required init(json: JSON) throws {
        show_id = try json["show_id"].int.required()
        show = json["show"].isEmpty ? nil : try Show(json: json["show"])
        
        description = json["description"].string
        taper_notes = json["taper_notes"].string
        source = json["source"].string
        taper = json["taper"].string
        transferrer = json["transferrer"].string
        lineage = json["lineage"].string
        
        guard let f = FlacType(rawValue: try json["flac_type"].string.required()) else {
            throw FlacTypeError.invalid(attempted: json["flac_type"].string)
        }
        
        flac_type = f

        try super.init(json: json)
    }
}

public class SourceFull : Source {
    public let review_count: Int
    public let sets: [SourceSet]
    public let links: [Link]
    
    public required init(json: JSON) throws {
        review_count = json["review_count"].int ?? -1
        sets = try json["sets"].arrayValue.map(SourceSet.init)
        links = try json["links"].arrayValue.map(Link.init)
        
        try super.init(json: json)
    }
    
    public var tracksFlattened: [SourceTrack] {
        return sinq(sets).selectMany({ $0.tracks }).toArray()
    }
}

extension SourceFull {
    public func flattenedIndex(forIndexPath: IndexPath) -> Int {
        let prevTrackCount = self.sets[0..<forIndexPath.section].map({ $0.tracks.count }).reduce(0, +)
        
        return prevTrackCount + forIndexPath.row
    }
}

public class Link : RelistenObject {
    public let source_id: Int
    public let upstream_source_id: Int
    public let for_reviews: Bool
    public let for_ratings: Bool
    public let for_source: Bool
    public let url: String
    public let label: String
    
    public required init(json: JSON) throws {
        source_id = try json["source_id"].int.required()
        upstream_source_id = try json["upstream_source_id"].int.required()
        
        for_reviews = try json["for_reviews"].bool.required()
        for_ratings = try json["for_ratings"].bool.required()
        for_source = try json["for_source"].bool.required()
        
        url = try json["url"].string.required()
        label = try json["label"].string.required()
        
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

public class SourceTrack : RelistenObject, RelistenUUIDObject {
    public let uuid: UUID
    
    public let source_id: Int
    public let source_set_id: Int
    
    public let track_position: Int
    public let duration: TimeInterval?
    
    public let title: String
    public let slug: String
    
    public let mp3_url: URL
    public let md5: String?
    
    public required init(json: JSON) throws {
        uuid = try json["uuid"].uuid.required()
        
        source_id = try json["source_id"].int.required()
        source_set_id = try json["source_set_id"].int.required()
        
        track_position = try json["track_position"].int.required()
        duration = json["duration"].double as TimeInterval?
        
        title = try json["title"].string.required()
        slug = try json["slug"].string.required()
        
        let m = try json["mp3_url"].string.required()
        mp3_url = URL(string: m.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
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
