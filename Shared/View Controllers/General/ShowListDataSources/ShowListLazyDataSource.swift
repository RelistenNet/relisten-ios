//
//  ShowListLazyDataSource.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/20/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation
import SINQ
import RealmSwift
import Observable

public class ShowListLazyDataSourceExtractor : ShowListArrayDataSourceShowExtractor {
    public typealias ExtractionTarget = [ShowSourceArtistUUIDs]
    public typealias FullMatchingData = ShowSourceArtistUUIDs
    
    public let providedArtist: ArtistWithCounts?
    
    public init(providedArtist: ArtistWithCounts? = nil) {
        self.providedArtist = providedArtist
    }

    public func extractShowAndSource(forData: ShowCellDataSource, withMatchingData: ShowSourceArtistUUIDs) -> ShowWithSingleSource? {
        guard let show = RelistenDb.shared.show(byUUID: forData.uuid) else {
            return nil
        }
        
        let artist = providedArtist ?? forData.artistDataSource
        let src = show.sources.first(where: { withMatchingData.sourceUUID == $0.uuid })
        
        return ShowWithSingleSource(show: show, source: src, artist: artist)
    }
    
    public func extractCellShows(forData: [ShowSourceArtistUUIDs]) -> [(ShowSourceArtistUUIDs, ShowCellDataSource)] {
        let dbShows = RelistenDb.shared.cellShows(byUUIDs: forData.map { $0.showUUID })
        return Array(zip(forData, dbShows as [ShowCellDataSource]))
    }
}

public class ShowListLazyDataSource : ShowListArrayDataSource<[ShowSourceArtistUUIDs], ShowSourceArtistUUIDs, ShowListLazyDataSourceExtractor> {
    private let ex: ShowListLazyDataSourceExtractor
    
    public init(providedArtist: ArtistWithCounts? = nil) {
        ex = ShowListLazyDataSourceExtractor(providedArtist: providedArtist)
        
        var sort: ShowSorting = .ascending
        if let _ = providedArtist?.shouldSortYearsDescending {
            sort = .descending
        }
        
        super.init(extractor: ex, sort: sort, tourSections: providedArtist != nil, artistSections: providedArtist == nil)
    }
}
