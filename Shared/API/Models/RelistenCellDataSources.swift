//
//  RelistenCellDataSources.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/22/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

public protocol VenueCellDataSource {
    var name: String { get }
    var past_names: String? { get }
    var location: String { get }
}

public protocol TourCellDataSource {
    var name: String { get }
    var start_date: Date { get }
    var end_date: Date { get }
}

public protocol SourceCellDataSource {
    var taper: String? { get }
    var transferrer: String? { get }
    var is_soundboard: Bool { get }
}

public protocol ShowCellDataSource: class {
    var uuid: UUID { get }
    
    var artist_id: Int { get }
    
    var display_date: String { get }
    var date: Date { get }
    var avg_rating: Float { get }
    var avg_duration: TimeInterval? { get }
    var most_recent_source_updated_at: Date { get }
    var has_soundboard_source: Bool { get }
    var source_count: Int { get }
    
    var venueDataSource: VenueCellDataSource? { get }
    var tourDataSource: TourCellDataSource? { get }
    var sourceDataSource: SourceCellDataSource? { get }
    var artistDataSource: ArtistWithCounts? { get }
}

extension VenueWithShowCount : VenueCellDataSource {
    
}

extension Tour : TourCellDataSource {
    
}

extension Show : ShowCellDataSource {
    public var venueDataSource: VenueCellDataSource? { get { return venue } }
    public var tourDataSource: TourCellDataSource? { get { return tour } }
    public var sourceDataSource: SourceCellDataSource? { get { return nil } }
    public var artistDataSource: ArtistWithCounts? {
        get {
            return RelistenCacher.artistFromCache(forId: artist_id)
        }
    }
}
