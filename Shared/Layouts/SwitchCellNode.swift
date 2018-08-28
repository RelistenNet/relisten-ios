//
//  SwitchCellNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import Observable
import ActionKit

public let StandardSwitchBounds = { () -> CGRect in
    var bounds : CGRect? = nil
    performOnMainQueueSync {
        let s = UISwitch()
        s.sizeToFit()
        
        bounds = s.bounds
    }
    return bounds!
}()

public class SwitchCellNode : ASCellNode {
    let observeChecked: Observable<Bool>
    
    var disposal = Disposal()
    
    public init(observeChecked: Observable<Bool>, withLabel label: String) {
        self.observeChecked = observeChecked
        
        self.labelNode = ASTextNode(label, textStyle: .body)
        self.switchNode = ASControlNode(viewBlock: {
            let s = UISwitch()
            s.sizeToFit()
            s.backgroundColor = .clear
            s.onTintColor = AppColors.primary
            return s
        })
        self.switchNode.isUserInteractionEnabled = true
        self.switchNode.backgroundColor = .clear
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    public override func didLoad() {
        super.didLoad()
        
        observeChecked.observe { (new, old) in
            DispatchQueue.main.async {
                if let sw = self.switchNode.view as? UISwitch, sw.isOn != new {
                    sw.isOn = new
                }
            }
        }.add(to: &disposal)
        
        if let sw = self.switchNode.view as? UISwitch {
            sw.addTarget(self, action: #selector(changeSwitch(_:)), for: .valueChanged)
        }
    }
    
    @objc func changeSwitch(_ sw: UISwitch) {
        observeChecked.value = sw.isOn
    }
    
    public let labelNode: ASTextNode
    public let switchNode: ASControlNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        switchNode.style.minSize = StandardSwitchBounds.size
        
        let stack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [labelNode, SpacerNode(), switchNode]
        )
        stack.style.alignSelf = .stretch

        let insets = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(0, 0, 0, 0),
            child: stack
        )
        insets.style.alignSelf = .stretch
        
        return insets
    }
}
