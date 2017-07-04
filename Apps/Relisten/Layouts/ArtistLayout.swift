//
//  ArtistLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 3/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit

public class ArtistLayout : InsetLayout<UIView> {
    public init(artist: ArtistWithCounts) {
        let artistName = LabelLayout(
            text: artist.name,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "artistName")
        
        let favoriteButton = SizeLayout<UIButton>(
            width: 64,
            height: 24,
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "favoriteArtist") { (button) in
                button.setTitle("Favorite", for: .normal)
                button.setTitleColor(.black, for: .normal)
            }
        
        let showsLabel = LabelLayout(
            text: "\(artist.show_count) shows",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerLeading,
            viewReuseId: "showCount"
        )
        
        let sourcesLabel = LabelLayout(
            text: "\(artist.source_count) recordings",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerTrailing,
            viewReuseId: "sourcesCount"
        )
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 12, right: 16 + 8 + 8),
            viewReuseId: "artistLayout",
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 4,
                sublayouts: [
                    StackLayout(
                        axis: .horizontal,
                        sublayouts: [
                            artistName,
                            favoriteButton
                        ]
                    ),
                    StackLayout(
                        axis: .horizontal,
                        sublayouts: [
                            showsLabel,
                            sourcesLabel
                        ]
                    )
                ]
            )
        )
    }
}
