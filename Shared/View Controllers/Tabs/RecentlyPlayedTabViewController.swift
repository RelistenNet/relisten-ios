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

class RecentlyPlayedTabViewController: NewShowListRealmViewController<RecentlyPlayedTrack>, UIViewControllerRestoration {
    public required init() {
        super.init(query: MyLibrary.shared.recent.shows, providedArtist: nil, enableSearch: false, tourSections: false, artistSections: false)
        
        self.restorationIdentifier = "RecentlyPlayedTabViewController"
        self.restorationClass = type(of: self)
        
        title = "My Recents"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
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
    
    override func titleTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Nothing played recently"
    }
    
    override func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Any shows you play will show up here in the ordered you played them."
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    override public func layout(show: ShowWithSingleSource, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show.show, showingArtist: show.artist) }
    }

    
    //MARK: State Restoration
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        return RecentlyPlayedTabViewController()
    }
}
