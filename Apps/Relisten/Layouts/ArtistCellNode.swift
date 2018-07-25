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
    public let favoriteArtists: [Int]
        
    let nameNode: ASTextNode
    let showsNode: ASTextNode
    let sourcesNode: ASTextNode
    let favoriteNode: FavoriteButtonNode
    
    public var favoriteButtonAccessibilityLabel : String { get { return "Favorite Artist" } }
    
    var disposal = Disposal()
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: [Int]) {
        self.artist = artist
        self.favoriteArtists = withFavoritedArtists
        
        nameNode = ASTextNode(artist.name, textStyle: .headline)
        showsNode = ASTextNode("\(artist.show_count) shows", textStyle: .caption1)
        sourcesNode = ASTextNode("\(artist.source_count) recordings", textStyle: .caption1)
        favoriteNode = FavoriteButtonNode()

        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        
        favoriteNode.currentlyFavorited = withFavoritedArtists.contains(artist.id)
        favoriteNode.delegate = self
        setupFavoriteObservers()
    }
    
    private func setupFavoriteObservers() {
        MyLibraryManager.shared.artistFavorited.addHandler({ [weak self] artist in
            self?.favoriteNode.currentlyFavorited = (self?.artist.id == artist.id)
        }).add(to: &disposal)
        
        MyLibraryManager.shared.artistUnfavorited.addHandler({ [weak self] artist in
            if self?.artist.id == artist.id {
                self?.favoriteNode.currentlyFavorited = false
            }
        }).add(to: &disposal)
        
        MyLibraryManager.shared.observeFavoriteArtistIds.observe({ [weak self] ids, _ in
            guard let s = self else { return }
            
            s.favoriteNode.currentlyFavorited = ids.contains(s.artist.id)
        }).add(to: &disposal)
    }
    
    public func didFavorite(currentlyFavorited : Bool) {
        if currentlyFavorited {
            MyLibraryManager.shared.favoriteArtist(artist: self.artist)
        }
        else {
            let _ = MyLibraryManager.shared.removeArtist(artist: self.artist)
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

public class FavoriteArtistButtonNode : FavoriteButtonNode {
    let artist: ArtistWithCounts
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: [Int]) {
        self.artist = artist
        super.init()
        
        currentlyFavorited = withFavoritedArtists.contains(artist.id)
        accessibilityLabelString = "Favorite Artist"
    }
    
    public override func didLoad() {
        super.didLoad()
        
        MyLibraryManager.shared.artistFavorited.addHandler({ [weak self] artist in
            self?.currentlyFavorited = self?.artist.id == artist.id
            self?.updateSelected()
        }).add(to: &disposal)
        
        MyLibraryManager.shared.artistUnfavorited.addHandler({ [weak self] artist in
            if self?.artist.id == artist.id {
                self?.currentlyFavorited = false
                self?.updateSelected()
            }
        }).add(to: &disposal)
        
        MyLibraryManager.shared.observeFavoriteArtistIds.observe({ [weak self] ids, _ in
            guard let s = self else { return }
            
            s.currentlyFavorited = ids.contains(s.artist.id)
            s.updateSelected()
        }).add(to: &disposal)
    }
    
    @objc public override func onFavorite() {
        super.onFavorite()
        
        if currentlyFavorited {
            MyLibraryManager.shared.favoriteArtist(artist: self.artist)
        }
        else {
            let _ = MyLibraryManager.shared.removeArtist(artist: self.artist)
        }
    }
}
