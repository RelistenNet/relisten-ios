//
//  UpstreamSourceNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/11/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class UpstreamSourceNode : ASCellNode {
    public let link: Link
    public let upstreamSource: UpstreamSource
    
    public init(link: Link, forUpstreamSource upstreamSource: UpstreamSource) {
        self.link = link
        self.upstreamSource = upstreamSource
        
        titleNode = ASTextNode(link.label, textStyle: .body)
        linkNode = ASTextNode(link.url, textStyle: .caption1)
        descriptionNode = ASTextNode(upstreamSource.description, textStyle: .subheadline)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
    }
    
    public let titleNode: ASTextNode
    public let linkNode: ASTextNode
    public let descriptionNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let upstreamInfo = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                titleNode,
                linkNode,
                descriptionNode
            )
        )
        upstreamInfo.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: upstreamInfo
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
