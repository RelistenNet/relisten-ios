//
//  LinkUpstreamNode.swift
//  RelistenShared
//
//  Created by Alec Gorge on 9/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public class LinkUpstreamNode : ASCellNode {
    let link: Link
    let upstreamSource: UpstreamSource?
    
    public init(forLink: Link, fromUpstreamSource: UpstreamSource?) {
        link = forLink
        upstreamSource = fromUpstreamSource
        
        titleNode = ASTextNode(link.label, textStyle: .body)
        linkNode = ASTextNode(link.url, textStyle: .caption1)
        
        if let u = upstreamSource {
            descriptionNode = ASTextNode(u.description, textStyle: .subheadline)
        }
        else {
            descriptionNode = nil
        }
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        accessibilityLabel = "Credits"
    }
    
    let titleNode: ASTextNode
    let linkNode: ASTextNode
    let descriptionNode: ASTextNode?
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                titleNode,
                linkNode,
                descriptionNode == nil ? nil : ASInsetLayoutSpec(insets: UIEdgeInsetsMake(4, 0, 0, 0), child: descriptionNode!)
            )
        )
        stack.style.alignSelf = .stretch
        
        let i = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(12, 16, 12, 32),
            child: stack
        )
        i.style.alignSelf = .stretch
        
        return i
    }
}
