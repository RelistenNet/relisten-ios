//
//  RelistenModels.swift
//  Relisten
//
//  Created by Alec Gorge on 2/24/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

public typealias SwJSON = JSON

public class RelistenObject {
    public let id: Int
    public let created_at: Date
    public let updated_at: Date
    
    public let originalJSON: JSON
    
    public required init(json: JSON) throws {
        id = try json["id"].int.required()
        created_at = try json["created_at"].dateTime.required()
        updated_at = try json["updated_at"].dateTime.required()
        
        originalJSON = json
    }
    
    public convenience required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .originalJson)
        
        try self.init(json: SwJSON(data: data))
    }
    
    
    public func toPrettyJSONString() -> String {
        return originalJSON.rawString(.utf8, options: .prettyPrinted)!
    }
    
    public func toData() throws -> Data {
        return try originalJSON.rawData()
    }
}

public struct Features {
    public let id : Int
    public let descriptions : Bool
    public let eras : Bool
    public let multiple_sources : Bool
    public let reviews : Bool
    public let ratings : Bool
    public let tours : Bool
    public let taper_notes : Bool
    public let source_information : Bool
    public let sets : Bool
    public let per_show_venues : Bool
    public let per_source_venues : Bool
    public let venue_coords : Bool
    public let songs : Bool
    public let years : Bool
    public let track_md5s : Bool
    public let review_titles : Bool
    public let jam_charts : Bool
    public let setlist_data_incomplete : Bool
    public let artist_id : Int
    public let track_names : Bool
    public let venue_past_names : Bool
    public let reviews_have_ratings : Bool
    public let track_durations : Bool
    public let can_have_flac : Bool

    public init(json: JSON) throws {
        id = try json["id"].int.required()
        descriptions = try json["descriptions"].bool.required()
        eras = try json["eras"].bool.required()
        multiple_sources = try json["multiple_sources"].bool.required()
        reviews = try json["reviews"].bool.required()
        ratings = try json["ratings"].bool.required()
        tours = try json["tours"].bool.required()
        taper_notes = try json["taper_notes"].bool.required()
        source_information = try json["source_information"].bool.required()
        sets = try json["sets"].bool.required()
        per_show_venues = try json["per_show_venues"].bool.required()
        per_source_venues = try json["per_source_venues"].bool.required()
        venue_coords = try json["venue_coords"].bool.required()
        songs = try json["songs"].bool.required()
        years = try json["years"].bool.required()
        track_md5s = try json["track_md5s"].bool.required()
        review_titles = try json["review_titles"].bool.required()
        jam_charts = try json["jam_charts"].bool.required()
        setlist_data_incomplete = try json["setlist_data_incomplete"].bool.required()
        artist_id = try json["artist_id"].int.required()
        track_names = try json["track_names"].bool.required()
        venue_past_names = try json["venue_past_names"].bool.required()
        reviews_have_ratings = try json["reviews_have_ratings"].bool.required()
        track_durations = try json["track_durations"].bool.required()
        can_have_flac = try json["can_have_flac"].bool.required()
    }
}
