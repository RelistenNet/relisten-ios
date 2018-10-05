//
//  VenueDetailsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/5/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public class VenueDetailsNode : ASCellNode {
    public let venue: VenueWithShowCount
    
    public init(venue: VenueWithShowCount) {
        self.venue = venue
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let venueInfo = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: ArrayNoNils(
                nil
            )
        )
        venueInfo.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: venueInfo
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
