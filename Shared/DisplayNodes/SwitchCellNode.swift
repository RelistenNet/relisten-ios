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

// (farkas) This code was deadlocking due to texture trying to load a switch node on the global queue
//  while the main queue was blocked waiting for the table view to update so it could reload.
// This code tries to mitigate that by asynchronously loading the bounds on the main thread,
//  then blocking whichever thread first asks for the bounds if they haven't loaded yet.
// We try to avoid deadlocks further by prefetching these bounds in SwitchCellNode.init.
// This is pretty ugly and probably too clever for its own good, but it seems to work.
// Better solutions are gladly welcomed!
var _standardSwitchBounds : CGRect?
public var StandardSwitchBounds : CGRect {
    get {
        return _standardSwitchBounds!
    }
    set {
        _standardSwitchBounds = newValue
    }
}

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
    
    public static func loadStandardSwitchBounds() {
        let s = UISwitch()
        s.sizeToFit()
        _standardSwitchBounds = s.bounds
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
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            child: stack
        )
        insets.style.alignSelf = .stretch
        
        return insets
    }
}
