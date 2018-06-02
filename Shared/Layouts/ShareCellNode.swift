//
//  ShareCellNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public class ShareCellNode : ASCellNode {
    public override init() {
        shareNode = ASTextNode("Share", textStyle: .body)
        
        super.init()
        
        accessoryType = .disclosureIndicator
        automaticallyManagesSubnodes = true
    }
    
    public let shareNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(12, 16, 12, 16),
            child: shareNode
        )
    }
}
