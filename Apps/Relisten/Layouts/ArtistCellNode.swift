//
//  ArtistLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 3/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import RelistenShared

import LayoutKit
import FaveButton

import AsyncDisplayKit
import Observable
import ActionKit

public class ArtistCellNode : ASCellNode, FavoriteButtonDelegate {
    public let artist: ArtistWithCounts
    public let favoriteArtists: [UUID]
        
    let nameNode: ASTextNode
    let showsNode: ASTextNode
    let sourcesNode: ASTextNode
    let favoriteNode: FavoriteButtonNode
    
    public var favoriteButtonAccessibilityLabel : String { get { return "Favorite Artist" } }
    
    var disposal = Disposal()
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: [UUID]) {
        self.artist = artist
        self.favoriteArtists = withFavoritedArtists
        
        nameNode = ASTextNode(artist.name, textStyle: .headline)
        showsNode = ASTextNode(artist.show_count.pluralize("show", "shows"), textStyle: .caption1)
        sourcesNode = ASTextNode(artist.source_count.pluralize("recording", "recordings"), textStyle: .caption1)
        favoriteNode = FavoriteButtonNode()

        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        
        favoriteNode.currentlyFavorited = withFavoritedArtists.contains(artist.uuid)
        favoriteNode.delegate = self
        setupFavoriteObservers()
    }
    
    private func setupFavoriteObservers() {
        DispatchQueue.main.async {
            let library = MyLibrary.shared
            
            library.favorites.artists.observeWithValue { [weak self] artists, changes in
                guard let s = self else { return }
                
                s.favoriteNode.currentlyFavorited = library.isFavorite(artist: s.artist)
            }.dispose(to: &self.disposal)
        }
    }
    
    public func didFavorite(currentlyFavorited : Bool) {
        if currentlyFavorited {
            MyLibrary.shared.favoriteArtist(artist: self.artist)
        }
        else {
            let _ = MyLibrary.shared.removeArtist(artist: self.artist)
        }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let bottomRow = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0.0,
            justifyContent: .spaceBetween,
            alignItems: .baselineFirst,
            children: [
                showsNode,
                sourcesNode
            ]
        )
        bottomRow.style.alignSelf = .stretch
        
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: [
                nameNode,
                bottomRow
            ]
        )
        stack.style.flexGrow = 1.0
        
        let containerStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8.0,
            justifyContent: .start,
            alignItems: .center,
            children: [
                favoriteNode,
                stack
            ]
        )
        containerStack.style.alignSelf = .stretch
        
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 0),
            child: containerStack
        )
        inset.style.alignSelf = .stretch
        
        return inset
    }
}
