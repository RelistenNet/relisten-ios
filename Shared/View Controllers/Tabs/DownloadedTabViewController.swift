//
//  DownloadedTabViewController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/22/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import RealmSwift

class DownloadedTabViewController: NewShowListRealmViewController<OfflineSource> {
    public required init(_ artist: SlimArtist? = nil) {
        let offline = MyLibrary.shared.offline
        super.init(query: artist != nil ? offline.sources(byArtist: artist!) : offline.sources)
        
        title = "Downloaded"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(query: Results<OfflineSource>, providedArtist artist: ArtistWithCounts?, enableSearch: Bool, tourSections: Bool?, artistSections: Bool?) {
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
        return "Nothing downloaded"
    }
    
    override func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Any tracks you download will show up here and will be available to play offline. You can download entire shows or just individual tracks."
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
}
