//
//  switchCellLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 10/22/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import LayoutKit

public class SwitchCellLayout : InsetLayout<UIView> {
    public static let standardSwitch: UISwitch = {
        let s = UISwitch()
        s.sizeToFit()
    
        return s
    }()
    
    public init(title: String, checkedByDefault: @escaping () -> Bool, onSwitch: @escaping (Bool) -> Void) {
        let label = LabelLayout(
            text: title,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .centerLeading,
            flexibility: .flexible,
            viewReuseId: "switch-title",
            config: nil
        )
        
        let switch_ = SizeLayout<UISwitch>(
            size: SwitchCellLayout.standardSwitch.bounds.size,
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "switch-switch",
            sublayout: nil) { (sw) in
                sw.isOn = checkedByDefault()
                
                sw.addHandler(for: .valueChanged) { _ in
                    sw.isOn = !sw.isOn
                    
                    onSwitch(sw.isOn)
                }
        }
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            viewReuseId: "switchCellLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 0,
                viewReuseId: "switch-cell-horiz-stack",
                sublayouts: [label, switch_]
            )
        )
    }
}

