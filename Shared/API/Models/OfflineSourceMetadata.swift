//
//  OfflineSourceMetadata.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/18/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public struct OfflineSourceMetadata : Codable, Hashable {
    public var hashValue: Int {
        return completeShowInformation.hashValue
    }
    
    public static func == (lhs: OfflineSourceMetadata, rhs: OfflineSourceMetadata) -> Bool {
        return lhs.completeShowInformation == rhs.completeShowInformation
    }
    
    public var year: String {
        let yearEnd = completeShowInformation.show.display_date.index(completeShowInformation.show.display_date.startIndex, offsetBy: 4)
        return String(completeShowInformation.show.display_date[..<yearEnd])
    }
    
    public var show: Show {
        return completeShowInformation.show
    }
    
    public var source: SourceFull {
        return completeShowInformation.source
    }
    
    public var artist: ArtistWithCounts {
        return completeShowInformation.artist
    }
    
    public let completeShowInformation: CompleteShowInformation
    
    public let dateAdded: Date
    
    public static func from(track: Track) -> OfflineSourceMetadata {
        return self.init(completeShowInformation: track.showInfo, dateAdded: Date())
    }
    
    private enum CodingKeys: String, CodingKey {
        case completeShowInformation
        case dateAdded
    }
}
