//
//  RelistenLegacyModels.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import SwiftyJSON

// These are the most barebones possible models to allow for importing data from the old API
public class LegacyObject {
    public let id: Int?
    
    public let originalJSON: JSON
    
    public required init(json: JSON) {
        id = json["id"].int
        
        originalJSON = json
    }
}

public class LegacyArtist : LegacyObject {
    public let name : String?
    public let slug : String?
    public let musicbrainz_id: String?
    
    public required init(json: JSON) {
        name = json["name"].string
        slug = json["slug"].string
        
        musicbrainz_id = json["musicbrainz_id"].string
        
        super.init(json: json)
    }
}

public class LegacyYear : LegacyObject {
    public let year : Int?
    public let shows : [LegacyShow]?
    
    public required init(json: JSON) {
        year = json["year"].int
        shows = json["shows"].arrayValue.map(LegacyShow.init)
        
        super.init(json: json)
    }
}

public class LegacyShow : LegacyObject {
    public let date : Date?
    public let displayDate : String?
    
    public required init(json: JSON) {
        date = json["date"].dateTime
        displayDate = json["display_date"].string
        
        super.init(json: json)
    }
}

public class LegacyShowWithTracks : LegacyShow {
    public let tracks : [LegacyTrack]?
    
    public required init(json: JSON) {
        tracks = json["tracks"].arrayValue.map(LegacyTrack.init)
        
        super.init(json: json)
    }
}

public class LegacyTrack : LegacyObject {
    public let title : String?
    public let slug : String?
    public let duration : TimeInterval?
    public let mp3_url : URL?
    public let md5 : String?
    
    public required init(json: JSON) {
        title = json["title"].string
        slug = json["slug"].string
        duration = json["length"].double as TimeInterval?
        if let mp3_string = json["mp3"].string {
            mp3_url = URL(string: mp3_string)
        } else {
            mp3_url = nil
        }
        md5 = json["md5"].string
        
        super.init(json: json)
    }
}
