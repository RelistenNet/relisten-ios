//
//  RelistenSongModels.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

// SongWithShowCount

public class Song : RelistenObject {
    public let artist_id: Int
    
    public let name: String
    public let slug: String
    
    public let upstream_identifier: String
    public let sortName: String
    
    public required init(json: JSON) throws {
        artist_id = try json["artist_id"].int.required()
        
        name = try json["name"].string.required()
        slug = try json["slug"].string.required()
        
        upstream_identifier = try json["upstream_identifier"].string.required()
        sortName = try json["sortName"].string.required()
        
        try super.init(json: json)
    }
}

public class SongWithShowCount : Song {
    public let shows_played_at: Int
    
    public required init(json: JSON) throws {
        shows_played_at = try json["shows_played_at"].int.required()
        
        try super.init(json: json)
    }
}

public class SongWithShows : Song {
    public let shows: [Show]
    
    public required init(json: JSON) throws {
        shows = try json["shows"].arrayValue.map(Show.init)
        
        try super.init(json: json)
    }
}
