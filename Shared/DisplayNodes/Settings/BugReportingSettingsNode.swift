//
//  BugReportingSettingsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Observable

public class BugReportingSettingsNode : ASCellNode {
    public override init() {
        bugReportingSwitch = SwitchCellNode(observeChecked: RelistenApp.sharedApp.shakeToReportBugEnabled, withLabel: "Enable bug reporting")
        bugReportingDescription = ASTextNode("Shake your \(UIDevice.current.model) to bring up a bug reporting screen", textStyle: .footnote, color: AppColors.mutedText)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    let bugReportingSwitch : SwitchCellNode
    let bugReportingDescription : ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let descInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 64),
            child: bugReportingDescription
        )
        descInset.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .stretch,
            children: [
                bugReportingSwitch,
                descInset
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
