//
//  YearNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import Observable

public class YearNode : ASCellNode {
    public let year: Year
    
    var disposal = Disposal()
    
    public init(year: Year) {
        self.year = year
        
        self.yearNameNode = ASTextNode(year.year, textStyle: .headline)
        self.ratingNode = AXRatingViewNode(value: year.avg_rating / 10.0)
        self.showsNode = ASTextNode("\(year.show_count) " + "show".pluralize(year.show_count), textStyle: .caption1)
        self.sourceNode = ASTextNode("\(year.source_count) " + "recording".pluralize(year.source_count), textStyle: .caption1)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        
        let library = MyLibraryManager.shared.library
        library.observeOfflineSources
            .observe({ [weak self] _, _ in
                guard let s = self else { return }
                
                if s.isAvailableOffline != library.isYearAtLeastPartiallyAvailableOffline(s.year) {
                    s.isAvailableOffline = !s.isAvailableOffline
                    s.setNeedsLayout()
                }
            })
            .add(to: &disposal)
    }
    
    public let yearNameNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    public let showsNode: ASTextNode
    public let sourceNode: ASTextNode
    public let offlineNode: OfflineIndicatorNode = OfflineIndicatorNode()
    
    public var isAvailableOffline = false
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let top = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [
                yearNameNode,
                ratingNode
            ]
        )
        top.style.alignSelf = .stretch
        
        let bottom = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(isAvailableOffline ? offlineNode : nil, showsNode, SpacerNode(), sourceNode)
        )
        bottom.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [
                top,
                bottom
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(8, 16, 8, 8),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
