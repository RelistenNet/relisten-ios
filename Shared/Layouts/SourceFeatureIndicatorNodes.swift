//
//  SoundboardIndicatorNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public class SoundboardIndicatorNode: ASDisplayNode {
    public override init() {
        sbdNode = ASTextNode("SBD", textStyle: .subheadline, color: AppColors.textOnPrimary)
        
        super.init()
        
        backgroundColor = AppColors.soundboard
        automaticallyManagesSubnodes = true
        
        cornerRadius = 3.0
    }
    
    let sbdNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(2, 2, 2, 2), child: sbdNode)
    }
}

public class RemasterIndicatorNode: ASDisplayNode {
    public override init() {
        sbdNode = ASTextNode("Remast", textStyle: .subheadline, color: AppColors.textOnPrimary)
        
        super.init()
        
        backgroundColor = AppColors.remaster
        automaticallyManagesSubnodes = true
        
        cornerRadius = 3.0
    }
    
    let sbdNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(2, 2, 2, 2), child: sbdNode)
    }
}

