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
    public required init(_ artist: SlimArtist? = nil) {
        let faves = MyLibrary.shared.favorites
        super.init(query: artist != nil ? faves.sources(byArtist: artist!) : faves.sources)
        
        self.restorationIdentifier = "net.relisten.MyLibraryTabViewController"
        self.restorationClass = type(of: self)
        
        title = "My Library"
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public required init(query: Results<FavoritedSource>, providedArtist artist: ArtistWithCounts?, enableSearch: Bool, tourSections: Bool?, artistSections: Bool?) {
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
        return "No shows favorited yet"
    }
    
    override func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Tap the heart on any source to start building your library."
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
