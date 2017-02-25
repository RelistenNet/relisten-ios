//
//  RelistenShowModels.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

public class Year : RelistenObject {
    public let show_count: Int
    public let source_count: Int
    
    public let duration: TimeInterval?
    public let avg_duration: TimeInterval?
    
    public let avg_rating: Float
    
    public let year: String
    public let artist_id: Int
    
    public required init(json: JSON) throws {
        show_count = try json["show_count"].int.required()
        source_count = try json["source_count"].int.required()
        
        duration = json["duration"].double as TimeInterval?
        avg_duration = json["avg_duration"].double as TimeInterval?
        
        avg_rating = try json["avg_rating"].float.required()
        
        year = try json["year"].string.required()
        artist_id = try json["artist_id"].int.required()
        
        try super.init(json: json)
    }
}

public class YearWithShows : Year {
    public let shows: [Show]
    
    public required init(json: JSON) throws {
        shows = try json["shows"].arrayValue.map(Show.init)
        
        try super.init(json: json)
    }
}

public class Show : RelistenObject {
    public let artist_id: Int
    
    public let venue_id: Int?
    public let venue: Venue?
    
    public let tour_id: Int?
    public let tour: Tour?
    
    public let year_id: Int
    // public let year (Year, optional),
    
    public let era_id: Int?
    public let era: Era?
    
    public let date: Date
    public let display_date: String
    
    public let avg_rating: Float
    
    public let avg_duration: TimeInterval?
    public let sources_count: Int
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        venue_id = json["venue_id"].int
        venue = !json["venue"].isEmpty ? try Venue(json: json) : nil
        
        tour_id = json["tour_id"].int
        tour = !json["tour"].isEmpty ? try Tour(json: json) : nil
        
        year_id = try json["year_id"].int.required()
        
        era_id = json["era_id"].int
        era = !json["era"].isEmpty ? try Era(json: json) : nil
        
        date = try json["date"].dateTime.required()
        display_date = try json["display_date"].string.required()
        
        avg_rating = try json["avg_rating"].float.required()
        
        avg_duration = json["avg_duration"].double as TimeInterval?
        sources_count = try json["sources_count"].int.required()
        
        try super.init(json: json)
    }
}

public class ShowWithSources : Show {
    public let sources: [SourceFull]
    
    public required init(json: JSON) throws {
        sources = try json["sources"].arrayValue.map(SourceFull.init)
        
        try super.init(json: json)
    }
}

public class Venue : RelistenObject {
    public let artist_id: Int
    
    public let latitude: Double?
    public let longitude: Double?
    
    public let name: String
    public let sortName: String

    public let slug: String

    public let location: String
    
    public let upstream_identifier: String
    
    public let past_names: String?
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        latitude = json["latitude"].double
        longitude = json["longitude"].double
        
        name = try json["name"].string.required()
        sortName = try json["sortName"].string.required()
        
        slug = try json["slug"].string.required()
        
        location = try json["location"].string.required()
        
        upstream_identifier = try json["upstream_identifier"].string.required()
        
        past_names = json["past_names"].string
        
        try super.init(json: json)
    }
}

public class VenueWithShowCount : Venue {
    public let shows_at_venue: Int
    
    public required init(json: JSON) throws {
        shows_at_venue = try json["shows_at_venue"].int.required()
        
        try super.init(json: json)
    }
}

public class VenueWithShows : VenueWithShowCount {
    public let shows: [Show]
    
    public required init(json: JSON) throws {
        shows = try json["shows"].arrayValue.map(Show.init)
        
        try super.init(json: json)
    }
}

public class Tour : RelistenObject {
    public let artist_id: Int
    
    public let start_date: Date
    public let end_date: Date
    
    public let name: String
    public let slug: String
    
    public let upstream_identifier: String
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        start_date = try json["start_date"].dateTime.required()
        end_date = try json["end_date"].dateTime.required()
        
        name = try json["name"].string.required()
        slug = try json["slug"].string.required()
        
        upstream_identifier = try json["upstream_identifier"].string.required()
        
        try super.init(json: json)
    }
}

public class TourWithShowCount : Tour {
    public let shows_on_tour : Int
    
    public required init(json: JSON) throws {
        shows_on_tour = try json["shows_on_tour"].int.required()
        
        try super.init(json: json)
    }
}

public class TourWithShows : Tour {
    public let shows: [Show]
    
    public required init(json: JSON) throws {
        shows = try json["shows"].arrayValue.map(Show.init)
        
        try super.init(json: json)
    }
}


public class Era : RelistenObject {
    public let artist_id: Int
    
    public let order: Int
    public let name: String
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        order = try json["order"].int.required()
        name = try json["name"].string.required()
        
        try super.init(json: json)
    }
}
