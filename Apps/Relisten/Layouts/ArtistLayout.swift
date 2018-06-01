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

import AsyncDisplayKit
import Observable

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

public func RelistenAttributedString(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment ?? NSTextAlignment.left
    
    return NSAttributedString(string: string, attributes: [
        NSAttributedStringKey.font: font,
        NSAttributedStringKey.foregroundColor: color ?? UIColor.darkText,
        NSAttributedStringKey.paragraphStyle: paragraphStyle
    ])
}

public func RelistenAttributedString(_ string: String, textStyle: UIFontTextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil) -> NSAttributedString {
    return RelistenAttributedString(string, font: UIFont.preferredFont(forTextStyle: textStyle), color: color, alignment: alignment)
}

extension ASTextNode {
    public convenience init(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, font: font, color: color, alignment: alignment)
    }

    public convenience init(_ string: String, textStyle: UIFontTextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, textStyle: textStyle, color: color, alignment: alignment)
    }
}

public func SpacerNode() -> ASLayoutSpec {
    let node = ASLayoutSpec()
    node.style.flexGrow = 1.0
    
    return node
}

public class FavoriteButtonNode : ASDisplayNode {
    public static let image = UIImage(named: "heart")

    let artist: ArtistWithCounts
    var currentlyFavorited: Bool
    
    let faveButtonNode: ASDisplayNode
    
    var disposal = Disposal()
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: [Int]) {
        self.artist = artist
        currentlyFavorited = withFavoritedArtists.contains(artist.id)
        
        faveButtonNode = ASDisplayNode(viewBlock: { FaveButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32)) })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    func updateSelected() {
        if let button = faveButtonNode.view as? FaveButton {
            button.setSelected(selected: currentlyFavorited, animated: false)
        }
    }
    
    public override func didLoad() {
        super.didLoad()
        
        if let button = faveButtonNode.view as? FaveButton {
            button.setImage(FavoriteButtonNode.image, for: .normal)
            button.accessibilityLabel = "Favorite Artist"
            
            button.delegate = ArtistLayout.faveButtonDelegate
            
            button.applyInit()
            
            button.setSelected(selected: currentlyFavorited, animated: false)
            
            button.addTarget(self, action: #selector(onFavorite), for: .touchUpInside)
        }
        
        MyLibraryManager.shared.artistFavorited.addHandler({ [weak self] artist in
            self?.currentlyFavorited = self?.artist.id == artist.id
            self?.updateSelected()
        }).add(to: &disposal)
        
        MyLibraryManager.shared.artistUnfavorited.addHandler({ [weak self] artist in
            if self?.artist.id == artist.id {
                self?.currentlyFavorited = false
                self?.updateSelected()
            }
        }).add(to: &disposal)
        
        MyLibraryManager.shared.observeFavoriteArtistIds.observe({ [weak self] ids, _ in
            guard let s = self else { return }
            
            s.currentlyFavorited = ids.contains(s.artist.id)
            s.updateSelected()
        }).add(to: &disposal)
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        faveButtonNode.style.layoutPosition = CGPoint(x: 0, y: 0)
        faveButtonNode.style.preferredSize = CGSize(width: 32, height: 32)
        
        return ASAbsoluteLayoutSpec(
            sizing: ASAbsoluteLayoutSpecSizing.sizeToFit,
            children: [ faveButtonNode ]
        )
    }
    
    @objc public func onFavorite() {
        currentlyFavorited = !currentlyFavorited
        
        if currentlyFavorited {
            MyLibraryManager.shared.favoriteArtist(artist: self.artist)
        }
        else {
            let _ = MyLibraryManager.shared.removeArtist(artist: self.artist)
        }
    }
}

public class ArtistCellNode : ASCellNode {
    public let artist: ArtistWithCounts
    public let favoriteArtists: [Int]
    
    let nameNode: ASTextNode
    let showsNode: ASTextNode
    let sourcesNode: ASTextNode
    let favoriteNode: FavoriteButtonNode
    
    public init(artist: ArtistWithCounts, withFavoritedArtists: [Int]) {
        self.artist = artist
        self.favoriteArtists = withFavoritedArtists
        
        nameNode = ASTextNode(artist.name, textStyle: .headline)
        showsNode = ASTextNode("\(artist.show_count) shows", textStyle: .caption1)
        sourcesNode = ASTextNode("\(artist.source_count) recordings", textStyle: .caption1)
        favoriteNode = FavoriteButtonNode(artist: artist, withFavoritedArtists: withFavoritedArtists)

        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let bottomRow = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0.0,
            justifyContent: .spaceBetween,
            alignItems: .baselineFirst,
            children: [
                showsNode,
                sourcesNode
            ]
        )
        bottomRow.style.alignSelf = .stretch
        
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: [
                nameNode,
                bottomRow
            ]
        )
        stack.style.flexGrow = 1.0
        
        let containerStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8.0,
            justifyContent: .start,
            alignItems: .center,
            children: [
                favoriteNode,
                stack
            ]
        )
        containerStack.style.alignSelf = .stretch
        
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 0),
            child: containerStack
        )
        inset.style.alignSelf = .stretch
        
        return inset
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
        
        /*
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
        */
        
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
            insets: EdgeInsets(top: 8, left: 16, bottom: 12, right: 16 + 8 + 8),
            viewReuseId: "artistLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 0,
                viewReuseId: "artist-horiz-stack",
                sublayouts: [/*favoriteButtonContainer, */ rows]
            )
        )
    }
}
