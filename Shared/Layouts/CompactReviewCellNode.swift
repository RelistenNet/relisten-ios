//
//  CompactReviewCellNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/11/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class CompactReviewCellNode : ASCellNode {
    public init(averageRating: Float, numRatings: Int?) {
        ratingTextNode = ASTextNode("Ratings", textStyle: .body)
        
        var detailText = String(format: "%.2f/10.00", averageRating)
        if let numRatings = numRatings {
            detailText += " (\(numRatings) ratings)"
        }
        ratingDetailNode = ASTextNode(detailText, textStyle: .body)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        accessibilityLabel = "Ratings"
    }
    
    let ratingTextNode: ASTextNode
    let ratingDetailNode: ASTextNode
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                ratingTextNode,
                SpacerNode(),
                ratingDetailNode
            )
        )
        stack.style.alignSelf = .stretch
        
        let i = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 0),
            child: stack
        )
        i.style.alignSelf = .stretch
        
        return i
    }
}
