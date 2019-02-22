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
        self.ratingTextNode = year.avg_rating == 0.0 ? nil : ASTextNode(String(format: "%.2f ★", year.avg_rating / 10.0 * 5.0), textStyle: .subheadline)
//        self.ratingNode = AXRatingViewNode(value: year.avg_rating / 10.0)
        self.showsNode = ASTextNode(year.show_count.pluralize("show", "shows"), textStyle: .caption1)
        self.sourceNode = ASTextNode(year.source_count.pluralize("recording", "recordings"), textStyle: .caption1)
        
        super.init()
        
        self.accessibilityLabel = "Year"
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        
        let library = MyLibrary.shared
        
        DispatchQueue.main.async {
            library.offline.sources.observeWithValue { [weak self] _, _ in
                guard let s = self else { return }
                
                if s.isAvailableOffline != library.isYearAtLeastPartiallyAvailableOffline(s.year) {
                    s.isAvailableOffline = !s.isAvailableOffline
                    s.setNeedsLayout()
                }
            }.dispose(to: &self.disposal)
        }
    }
    
    public let yearNameNode: ASTextNode
//    public let ratingNode: AXRatingViewNode
    public let ratingTextNode: ASTextNode?
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
            children: ArrayNoNils(
                yearNameNode,
                ratingTextNode
            )
        )
        top.style.alignSelf = .stretch
        
        let bottom = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(showsNode, isAvailableOffline ? offlineNode : nil, SpacerNode(), sourceNode)
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
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
