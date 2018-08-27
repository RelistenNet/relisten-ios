//
//  CreditsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public class CreditsNode : ASCellNode {
    public override init() {
        appIconNode = ASImageNode()
        appIconNode.image = RelistenApp.sharedApp.appIcon
        appIconNode.style.maxWidth = .init(unit: .points, value: 120)
        appIconNode.style.maxHeight = .init(unit: .points, value: 120)
        appIconNode.style.preferredSize = CGSize(width: appIconNode.style.maxWidth.value, height: appIconNode.style.maxHeight.value)
        appIconNode.style.flexShrink = 1.0
        
        appNameNode = ASTextNode(RelistenApp.sharedApp.appName, textStyle: .headline)
        appVersionNode = ASTextNode("Version \(RelistenApp.sharedApp.appVersion) (build \(RelistenApp.sharedApp.appBuildVersion))", textStyle: .caption1)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    public let appIconNode : ASImageNode
    public let appNameNode : ASTextNode
    public let appVersionNode : ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let appHeader = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [
                appIconNode,
                appNameNode,
                appVersionNode
            ]
        )
        appHeader.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [
                appHeader
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(40, 0, 0, 0),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
