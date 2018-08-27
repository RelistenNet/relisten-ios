//
//  BugReportingSettingsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class BugReportingSettingsNode : ASCellNode {
    public override init() {
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [
                
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
