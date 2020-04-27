//
//  CompleteShowInformation.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/4/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class CompleteShowInformation : Hashable  {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(artist.id)
        hasher.combine(show.display_date)
        hasher.combine(source.upstream_identifier)
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
    public let artist: ArtistWithCounts
  
    public required init(source: SourceFull, show: Show, artist: ArtistWithCounts) {
        self.source = source
        self.show = show
        self.artist = artist
    }
    
    public var completeTracksFlattened : [Track] {
        return source.tracksFlattened
            .map({ Track(sourceTrack: $0, showInfo: self) })
    }
}
