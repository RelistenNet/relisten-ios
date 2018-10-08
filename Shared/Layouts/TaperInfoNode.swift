//
//  TaperInfoNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/8/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class TaperInfoNode : ASCellNode {
    let source: SourceFull
    
    public init(source: SourceFull, includeDetails: Bool = false) {
        self.source = source
        
        var taperName : String? = nil
        
        if let s = source.taper, s.count > 0 {
            taperName = s
            
            taperNode = ASTextNode()
            taperNode?.attributedText = String.createPrefixedAttributedText(prefix: "Taper: ", taperName)
        } else {
            taperNode = nil
        }
        
        if let s = source.transferrer, s.count > 0 {
            if s != taperName {
                transferrerNode = ASTextNode()
                transferrerNode?.attributedText = String.createPrefixedAttributedText(prefix: "Transferrer: ", s)
            } else {
                // Don't show a transferrer if the name is identical to the taper
                transferrerNode = nil
            }
        } else {
            transferrerNode = nil
        }
        
        if let s = source.source, s.count > 0 {
            sourceNode = ASTextNode()
            sourceNode?.attributedText = String.createPrefixedAttributedText(prefix: "Source: ", s)
        } else {
            sourceNode = nil
        }
        
        if let s = source.lineage, s.count > 0 {
            lineageNode = ASTextNode()
            lineageNode?.attributedText = String.createPrefixedAttributedText(prefix: "Lineage: ", s)
        } else {
            lineageNode = nil
        }
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    let taperNode : ASTextNode?
    let transferrerNode : ASTextNode?
    let sourceNode : ASTextNode?
    let lineageNode : ASTextNode?
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let infoStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                taperNode,
                taperNode != nil ? SpacerNode() : nil,
                transferrerNode,
                transferrerNode != nil ? SpacerNode() : nil,
                sourceNode,
                sourceNode != nil ? SpacerNode() : nil,
                lineageNode
            )
        )
        infoStack.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 16),
            child: infoStack
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
