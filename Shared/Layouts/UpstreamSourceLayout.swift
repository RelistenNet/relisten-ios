//
//  UpstreamSourceLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import LayoutKit

public class UpstreamSourceLayout : InsetLayout<UIView> {
    public init(upstreamSource: UpstreamSource) {
        let titleLabel = LabelLayout(
            text: upstreamSource.name,
            font: UIFont.preferredFont(forTextStyle: .headline),
            alignment: .centerLeading,
            flexibility: .inflexible,
            viewReuseId: "upstreamTitle",
            config: nil
        )
        
        let descriptionLabel = LabelLayout(
            text: upstreamSource.description,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .centerLeading,
            flexibility: .inflexible,
            viewReuseId: "upstreamDesc",
            config: nil
        )
        
        let stack = StackLayout(
            axis: .vertical,
            spacing: 8,
            sublayouts: [
                titleLabel,
                descriptionLabel
            ]
        )
        
        super.init(
            insets: UIEdgeInsetsMake(12, 16, 12, 32),
            viewReuseId: "upstream",
            sublayout: stack
        )
    }
}

public class LinkLayout : InsetLayout<UIView> {
    public init(link: Link, forUpstreamSource: UpstreamSource) {
        let titleLabel = LabelLayout(
            text: link.label,
            font: UIFont.preferredFont(forTextStyle: .body),
            alignment: .centerLeading,
            flexibility: .inflexible,
            viewReuseId: "linkTitle",
            config: nil
        )
        
        let linkLabel = LabelLayout(
            text: link.url,
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 0,
            alignment: .centerLeading,
            flexibility: .inflexible,
            viewReuseId: "linkLink",
            config: nil
        )
        
        let descriptionLabel = LabelLayout(
            text: forUpstreamSource.description,
            font: UIFont.preferredFont(forTextStyle: .subheadline),
            numberOfLines: 0,
            alignment: .centerLeading,
            flexibility: .inflexible,
            viewReuseId: "linkUpstream",
            config: nil
        )
        
        let stack = StackLayout(
            axis: .vertical,
            spacing: 4,
            sublayouts: [
                titleLabel,
                linkLabel,
                InsetLayout(insets: UIEdgeInsetsMake(8, 0, 0, 0), sublayout: descriptionLabel)
            ]
        )
        
        super.init(
            insets: UIEdgeInsetsMake(12, 16, 12, 32),
            viewReuseId: "link",
            sublayout: stack
        )
    }
}
