//
//  CompleteShowInformation.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/4/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class CompleteShowInformation : Codable, Hashable  {
    public var hashValue: Int {
        return artist.id.hashValue ^ show.display_date.hashValue ^ source.upstream_identifier.hashValue
    }
    
    public static func == (lhs: CompleteShowInformation, rhs: CompleteShowInformation) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    public func isEqual(_ other: CompleteShowInformation) -> Bool {
        return artist.id == other.artist.id &&
            ((show.id == other.show.id && source.id == other.source.id) ||
                (show.display_date == other.show.display_date && other.source.upstream_identifier == source.upstream_identifier))
    }
    
    public let source: SourceFull
    public let show: Show
    public let artist: Artist
    
    public var originalJSON: SwJSON
    
    public required init(source: SourceFull, show: Show, artist: Artist) {
        self.source = source
        self.show = show
        self.artist = artist
        
        var j = SwJSON([:])
        j["source"] = source.originalJSON
        j["show"] = show.originalJSON
        j["artist"] = artist.originalJSON
        
        originalJSON = j
    }
    
    public required init(json: SwJSON) throws {
        source = try SourceFull(json: json["source"])
        show = try Show(json: json["show"])
        artist = try ArtistWithCounts(json: json["artist"])
        
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
    
    enum CodingKeys: String, CodingKey
    {
        case originalJson
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toData(), forKey: .originalJson)
    }
    
    public var completeTracksFlattened : [Track] {
        return source.tracksFlattened
            .map({ Track(sourceTrack: $0, showInfo: self) })
    }
}
