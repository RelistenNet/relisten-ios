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
    
    var height: CGFloat = 0
    
    public var shows: [(show: Show, artist: Artist?)] {
        didSet {
            DispatchQueue.main.async {
                var maxHeight : CGFloat = 103
                
                // based on: https://github.com/TextureGroup/Texture/issues/108#issuecomment-298416171
                if self.shows.count > 0, self.collectionNode.numberOfSections > 0 {
                    // [node layoutThatFits:element.constrainedSize].size.height;
                    let nodeCount = self.collectionNode.numberOfItems(inSection: 0)
                    
                    let sizeRange = ASSizeRange(min: CGSize.zero, max: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
                    
                    let maxSize = (0..<nodeCount).map {
                        self.collectionNode
                            .nodeForItem(at: IndexPath(row: 0, section: $0))?
                            .calculateLayoutThatFits(sizeRange)
                            .size
                            .height
                    }
                        .filter { $0 != nil }
                        .map { $0! }
                        .max()
                    
                    if let max = maxSize {
                        maxHeight = max
                    }
                }
                
                self.collectionNode.style.minHeight = ASDimension(unit: .points, value: maxHeight)
                
                self.collectionNode.setNeedsLayout()
                
                self.collectionNode.reloadData()
            }
        }
    }
    
    public init(forShows shows: [(show: Show, artist: Artist?)], delegate: ASCollectionDelegate?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
//        flowLayout.estimatedItemSize = CGSize(width: 280, height: 85)
//        flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 4, 4)
        
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

        collectionNode.style.preferredLayoutSize = ASLayoutSizeMake(.init(unit: .fraction, value: 1.0), .init(unit: .points, value: height))

        let wrapper = ASWrapperLayoutSpec(layoutElement: collectionNode)
        wrapper.style.alignSelf = .stretch
        
        self.style.alignSelf = .stretch
        
        return wrapper
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
        
        return { ShowCellNode(show: show.show, withRank: nil, useCellLayout: true, showingArtist: show.artist, cellTransparency: cellTransparency) }
    }
}

