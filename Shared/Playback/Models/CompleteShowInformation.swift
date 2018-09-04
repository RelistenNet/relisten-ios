//
//  CompleteShowInformation.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/4/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class CompleteShowInformation : Hashable  {
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
  
    public required init(source: SourceFull, show: Show, artist: Artist) {
        self.source = source
        self.show = show
        self.artist = artist
    }
    
    public var completeTracksFlattened : [Track] {
        return source.tracksFlattened
            .map({ Track(sourceTrack: $0, showInfo: self) })
    }
}
