//
//  ShareCellLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit

public class ShareCellLayout : InsetLayout<UIView> {
    public init() {
        let shareLabel = LabelLayout(
            text: "Share",
            font: UIFont.preferredFont(forTextStyle: .body),
            alignment: .centerLeading,
            flexibility: .flexible,
            viewReuseId: "shareLabel",
            config: nil
        )
        
        let stack = StackLayout(
            axis: .horizontal,
            viewReuseId: "shareStack",
            sublayouts: [
                shareLabel
            ]
        )
        
        super.init(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 32),
            alignment: .fill,
            viewReuseId: "shareCell",
            sublayout: stack,
            config: nil
        )
    }
}
