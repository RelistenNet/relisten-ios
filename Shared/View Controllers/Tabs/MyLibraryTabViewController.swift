//
//  FavoritesTabViewController.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/19/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import RealmSwift

class MyLibraryTabViewController: NewShowListRealmViewController<FavoritedSource>, UIViewControllerRestoration {
    public required init() {
        super.init(query: MyLibrary.shared.favorites.sources)
        
        self.restorationIdentifier = "net.relisten.MyLibraryTabViewController"
        self.restorationClass = type(of: self)
        
        title = "My Library"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(query: Results<FavoritedSource>, providedArtist artist: ArtistWithCounts?, enableSearch: Bool) {
        fatalError("init(query:providedArtist:enableSearch:) has not been implemented")
    }

    public required init(withDataSource dataSource: ShowListLazyDataSource, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    //MARK: State Restoration
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        return MyLibraryTabViewController()
    }
}
