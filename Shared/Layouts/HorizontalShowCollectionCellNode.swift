//
//  HorizontalShowCollectionCellNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import Observable

public class HorizontalShowCollectionCellNode : ASCellNode, ASCollectionDataSource {
    public let collectionNode: ASCollectionNode
    
    var disposal = Disposal()
    
    public var shows: [(show: Show, artist: ArtistWithCounts?)] {
        didSet {
            DispatchQueue.main.async {
                self.collectionNode.reloadData()
            }
        }
    }
    
    public init(forShows shows: [(show: Show, artist: ArtistWithCounts?)], delegate: ASCollectionDelegate?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 16
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 170, height: 145)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 4, 4)
        
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        self.shows = shows
        
        super.init()
        
        collectionNode.dataSource = self
        collectionNode.delegate = delegate
        collectionNode.setNeedsLayout()
        
        automaticallyManagesSubnodes = true
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.alignSelf = .stretch
        collectionNode.style.preferredLayoutSize = ASLayoutSizeMake(.init(unit: .fraction, value: 1.0), .init(unit: .points, value: 165))
        
        let l = ASAbsoluteLayoutSpec(sizing: .default, children: [collectionNode])
        l.style.minHeight = .init(unit: .points, value: 165)
        
        return l
    }
    
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return shows.count > 0 ? 1 : 0
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return shows.count
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let show = shows[indexPath.row]
        
        return { YearShowCellNode(show: show.show, withRank: nil, verticalLayout: true, showingArtist: show.artist) }
    }
}

