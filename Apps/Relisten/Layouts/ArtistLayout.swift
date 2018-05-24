//
//  ArtistLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 3/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import FaveButton

func color(_ rgbColor: Int) -> UIColor{
    return UIColor(
        red:   CGFloat((rgbColor & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbColor & 0x00FF00) >> 8 ) / 255.0,
        blue:  CGFloat((rgbColor & 0x0000FF) >> 0 ) / 255.0,
        alpha: CGFloat(1.0)
    )
}

public class RelistenFaveButtonDelegate : FaveButtonDelegate {
    let colors = [
        DotColors(first: color(0x7DC2F4), second: color(0xE2264D)),
        DotColors(first: color(0xF8CC61), second: color(0x9BDFBA)),
        DotColors(first: color(0xAF90F4), second: color(0x90D1F9)),
        DotColors(first: color(0xE9A966), second: color(0xF8C852)),
        DotColors(first: color(0xF68FA7), second: color(0xF6A2B8))
    ]
    
    public func faveButton(_ faveButton: FaveButton, didSelected selected: Bool) {
    }
    
    public func faveButtonDotColors(_ faveButton: FaveButton) -> [DotColors]?{
        return colors
    }
    
    public func instantCallback(_ faveButton: FaveButton, didSelected selected: Bool) {
        
    }
}

public class ArtistLayout : InsetLayout<UIView> {
    static let faveButtonDelegate = RelistenFaveButtonDelegate()
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: Set<Int>) {
        let artistName = LabelLayout(
            text: artist.name,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "artistName")
        
        let favoriteButton = SizeLayout<FaveButton>(
            width: 32,
            height: 32,
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "favoriteArtist") { (button) in
                button.setImage(UIImage(named: "heart"), for: .normal)
                button.accessibilityLabel = "Favorite Artist"
                
                var currentlyFavorited = withFavoritedArtists.contains(artist.id)

                button.delegate = ArtistLayout.faveButtonDelegate
                
                button.applyInit()
                
                button.setSelected(selected: currentlyFavorited, animated: false)

                button.addHandler(for: .touchUpInside, handler: { _ in
                    currentlyFavorited = !currentlyFavorited
                    
                    if currentlyFavorited {
                        MyLibraryManager.shared.favoriteArtist(artist: artist)
                    }
                    else {
                        let _ = MyLibraryManager.shared.removeArtist(artist: artist)
                    }
                })
            }
 
        let favoriteButtonContainer = InsetLayout(insets: UIEdgeInsetsMake(0, 16, 0, 8), sublayout: favoriteButton)

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
        
        let hasOffline = MyLibraryManager.shared.library.isArtistAtLeastPartiallyAvailableOffline(artist)
        
        let rows = StackLayout(
            axis: .vertical,
            spacing: 4,
            viewReuseId: "artist-vert-stack",
            sublayouts: [
                StackLayout(
                    axis: .horizontal,
                    spacing: 0,
                    sublayouts: [artistName]
                ),
                StackLayout(
                    axis: .horizontal,
                    spacing: 4,
                    sublayouts: hasOffline ? [
                        RelistenMakeOfflineExistsIndicator(),
                        showsLabel,
                        sourcesLabel
                    ] : [
                        showsLabel,
                        sourcesLabel
                    ]
                )
            ]
        )

        super.init(
            insets: EdgeInsets(top: 8, left: 0, bottom: 12, right: 16 + 8 + 8),
            viewReuseId: "artistLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 0,
                viewReuseId: "artist-horiz-stack",
                sublayouts: [favoriteButtonContainer, rows]
            )
        )
    }
}
