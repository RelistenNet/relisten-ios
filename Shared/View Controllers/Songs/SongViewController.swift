//
//  SongViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

class ShowListSongDataSourceExtractor : ShowListWrappedArrayDataSourceExtractor<SongWithShows, Show> {
    public override func extractShowList(forData wrapper: SongWithShows) -> [Show] {
        return wrapper.shows
    }
}

class SongViewController: NewShowListWrappedArrayViewController<SongWithShows, Show> {
    let song: Song
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts, song: Song) {
        self.song = song
        self.artist = artist
        
        super.init(
            extractor: ShowListSongDataSourceExtractor(providedArtist: artist),
            sort: .ascending,
            tourSections: false,
            artistSections: false,
            enableSearch: true
        )
        
        title = song.name
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(enableSearch: Bool) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    public required init(extractor: ShowListWrappedArrayDataSourceExtractor<SongWithShows, Show>, sort: ShowSorting = .descending, tourSections: Bool = true, artistSections: Bool = false, enableSearch: Bool = true) {
        fatalError("init(extractor:sort:tourSections:artistSections:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<SongWithShows, Show, ShowListWrappedArrayDataSourceExtractor<SongWithShows, Show>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    override public var resource: Resource? {
        get {
             return RelistenApi.shows(withPlayedSong: song, byArtist: artist)
        }
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
