//
//  SongLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import LayoutKit

public class SongLayout : InsetLayout<UIView> {
    public init(song: SongWithShowCount) {
        let songName = LabelLayout(
            text: song.name,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "songName"
        )
        
        let showsLabel = LabelLayout(
            text: song.shows_played_at.pluralize("show", "shows"),
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .fillTrailing,
            flexibility: .inflexible,
            viewReuseId: "songShowCount"
        )
        
        super.init(
            insets: EdgeInsets(top: 12, left: 16, bottom: 12, right: 16 + 8 + 8 + 16),
            viewReuseId: "songLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 8,
                sublayouts: [
                    songName,
                    showsLabel
                ]
            )
        )
    }
}
