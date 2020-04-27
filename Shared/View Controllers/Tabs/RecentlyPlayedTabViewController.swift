//
//  RecentTabViewController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/25/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import RealmSwift

class RecentlyPlayedTabViewController: NewShowListRealmViewController<RecentlyPlayedTrack> {
    public required init(_ artist: SlimArtist? = nil) {
        let recent = MyLibrary.shared.recent
        super.init(
            query: artist != nil ? recent.shows(byArtist: artist!) : recent.shows,
            // no need to provide the artist because each DB show will have the artist
            providedArtist: nil,
            enableSearch: false,
            tourSections: false,
            artistSections: false
        )

        title = "My Recents"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(query: Results<RecentlyPlayedTrack>, providedArtist artist: ArtistWithCounts?, enableSearch: Bool, tourSections: Bool?, artistSections: Bool?) {
        fatalError("init(query:providedArtist:enableSearch:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListLazyDataSource, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(enableSearch: Bool) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    override func titleTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Nothing played recently"
    }
    
    override func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Any shows you play will show up here in the ordered you played them."
    }
    
    override public func layout(show: ShowWithSingleSource, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show.show, showingArtist: show.artist) }
    }
        
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }

}
