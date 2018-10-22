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
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2), child: sbdNode)
    }
}

public class SmallSoundboardIndicatorNode: ASDisplayNode {
    public override init() {
        sbdNode = ASTextNode("SBD", textStyle: .caption2, color: AppColors.textOnPrimary)
        
        super.init()
        
        backgroundColor = AppColors.soundboard
        automaticallyManagesSubnodes = true
        
        cornerRadius = 2.0
    }
    
    let sbdNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), child: sbdNode)
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
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2), child: sbdNode)
    }
}

