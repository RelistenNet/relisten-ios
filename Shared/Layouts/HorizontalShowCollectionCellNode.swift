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
    public var cellTransparency : CGFloat = 1.0
    
    var disposal = Disposal()
    
    public var shows: [(show: Show, artist: Artist?)] {
        didSet {
            DispatchQueue.main.async {
                self.collectionNode.reloadData()
            }
        }
    }
    
    public init(forShows shows: [(show: Show, artist: Artist?)], delegate: ASCollectionDelegate?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 16
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 280, height: 85)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 4, 4)
        
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        collectionNode.backgroundColor = UIColor.clear
        
        self.shows = shows
        
        super.init()
        
        collectionNode.dataSource = self
        collectionNode.delegate = delegate
        collectionNode.setNeedsLayout()
        
        automaticallyManagesSubnodes = true
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.alignSelf = .stretch
        collectionNode.style.preferredLayoutSize = ASLayoutSizeMake(.init(unit: .fraction, value: 1.0), .init(unit: .points, value: 114.0 /* height + 8px padding on top and bottom */))
        
//        let l = ASAbsoluteLayoutSpec(sizing: .default, children: [collectionNode])
//        l.style.minHeight = .init(unit: .fraction, value: 1.0)
//        l.style.alignSelf = .stretch
        
        let i = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(0,0,0,0),
            child: collectionNode
        )
        i.style.alignSelf = .stretch
        
        return i
    }
    
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return shows.count > 0 ? 1 : 0
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return shows.count
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let show = shows[indexPath.row]
        let cellTransparency = self.cellTransparency
        
        return { ShowCellNode(show: show.show, withRank: nil, verticalLayout: true, showingArtist: show.artist, cellTransparency: cellTransparency) }
    }
}

