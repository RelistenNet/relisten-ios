//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

import AsyncDisplayKit
import Observable

public class ShowCellNode : ASCellNode {
    public let show: Show
    public let artist: SlimArtist?
    public let rank: Int?
    public let useCellLayout: Bool
    
    var disposal = Disposal()
    
    public init(show: Show, withRank: Int? = nil, useCellLayout: Bool = false, showingArtist: SlimArtist? = nil, showUpdateDate : Bool = false, cellTransparency : CGFloat = 1.0) {
        self.show = show
        artist = showingArtist
        rank = withRank
        self.useCellLayout = useCellLayout
        
        if let artist = showingArtist {
            artistNode = ASTextNode(artist.name, textStyle: .caption1)
        }
        else {
            artistNode = nil
        }
        
        showNode = ASTextNode(show.display_date, textStyle: .headline)
        
        var venueText = " \n "
        if let v = show.venue {
            if v.location.count > 0 && useCellLayout {
                venueText = v.location
            }
            else if v.name.count > 0 && useCellLayout {
                venueText = v.name
            }
            else {
                venueText = "\(v.name)\n\(v.location)"
            }
        }
        
        venueNode = ASTextNode(venueText, textStyle: .caption1)
        venueNode.maximumNumberOfLines = 0
        
//        ratingNode = AXRatingViewNode(value: show.avg_rating / 10.0)
        ratingTextNode = ASTextNode(String(format: "%.2f ★", show.avg_rating / 10.0 * 5.0), textStyle: .caption1)
        
        var metaText = "\(show.avg_duration == nil ? "" : show.avg_duration!.humanize())"
        if !useCellLayout {
            metaText += "\n\(show.source_count.pluralize("recording", "recordings"))"
        }
        
        metaNode = ASTextNode(metaText, textStyle: .caption1, color: nil, alignment: useCellLayout ? nil : NSTextAlignment.right)
        
        if showUpdateDate {
            let updateDate = DateFormatter.localizedString(from: show.most_recent_source_updated_at, dateStyle: .long, timeStyle: .none)
            let updateDateText = "Updated " + updateDate
            updateDateNode = ASTextNode(updateDateText, textStyle: .caption2, color: AppColors.mutedText)
        }
        else {
            updateDateNode = nil
        }
        
        if let rank = withRank {
            rankNode = ASTextNode("#\(rank)", textStyle: .headline, color: AppColors.mutedText)
        }
        else {
            rankNode = nil
        }
        
        if show.has_soundboard_source {
            soundboardIndicatorNode = useCellLayout ? SmallSoundboardIndicatorNode() : SoundboardIndicatorNode()
        }
        else {
            soundboardIndicatorNode = nil
        }
        
        isAvailableOffline = MyLibrary.shared.isShowAtLeastPartiallyAvailableOffline(self.show)
        
        artworkNode = ASImageNode()
        artworkNode.style.maxWidth = .init(unit: .points, value: useCellLayout ? 60.0 : 90)
        artworkNode.style.maxHeight = .init(unit: .points, value: useCellLayout ? 60.0 : 90)
        artworkNode.style.preferredSize = CGSize(width: artworkNode.style.maxWidth.value, height: artworkNode.style.maxHeight.value)
        
        artworkNode.backgroundColor = show.fastImageCacheWrapper().placeholderColor()
        artworkNode.style.flexShrink = 1.0
        
        super.init()
        
        if cellTransparency == 1.0 {
            self.backgroundColor = UIColor.white
        } else if cellTransparency == 0.0 {
            self.backgroundColor = UIColor.clear
        } else {
            self.backgroundColor = UIColor(white: 1.0, alpha: cellTransparency)
        }
        
        automaticallyManagesSubnodes = true
        
        if useCellLayout {
//            borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
//            borderWidth = 1.0
//            cornerRadius = 3.0
        }
        else {
            accessoryType = .disclosureIndicator
        }
    }
    
    public let artworkNode : ASImageNode
    
    public let artistNode: ASTextNode?
    public let showNode: ASTextNode
//    public let ratingNode: AXRatingViewNode
    public let ratingTextNode: ASTextNode
    
    public let venueNode: ASTextNode
    public let metaNode: ASTextNode
    public let updateDateNode : ASTextNode?
    
    public let rankNode: ASTextNode?
    public let offlineIndicatorNode = OfflineIndicatorNode()
    public let soundboardIndicatorNode: ASDisplayNode?
    
    var isAvailableOffline = false
    
    public override func didLoad() {
        super.didLoad()
        
        let library = MyLibrary.shared
        
        DispatchQueue.main.async {
            library.offline.sources.observeWithValue { [weak self] _, changes in
                guard let s = self else { return }
                
                if s.isAvailableOffline != library.isShowAtLeastPartiallyAvailableOffline(s.show) {
                    s.isAvailableOffline = !s.isAvailableOffline
                    s.setNeedsLayout()
                }
            }.dispose(to: &self.disposal)
        }
        
        AlbumArtImageCache.shared.cache.asynchronouslyRetrieveImage(for: show.fastImageCacheWrapper(), withFormatName: AlbumArtImageCache.imageFormatSmall) { [weak self] (_, _, i) in
            guard let s = self else { return }
            guard let image = i else { return }
            s.artworkNode.image = image
            s.setNeedsLayout()
        }
    }
    
    private func cellLayoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let showAndOffline = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [ showNode]
        )
        showAndOffline.style.alignSelf = .stretch
        
        var verticalStack: [ASLayoutElement] = [
            showAndOffline,
            venueNode
        ]
        
        var metaStack: [ASLayoutElement] = []
        
        metaStack.append(metaNode)
        
        if show.avg_rating > 0.0 {
            metaStack.append(SpacerNode())
            metaStack.append(ratingTextNode)
        }
        
        let vs = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: metaStack
        )
        vs.style.minHeight = .init(unit: .points, value: 22.0)
        vs.style.alignSelf = .stretch
        
        verticalStack.append(vs)
        
        let textStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 2,
            justifyContent: .end,
            alignItems: .start,
            children: verticalStack
        )
        textStack.style.alignSelf = .stretch
        
        if let sbd = soundboardIndicatorNode {
            sbd.style.layoutPosition = CGPoint(x: 3, y: 3)
        }
        
        let artSize = artworkNode.style.preferredSize
        offlineIndicatorNode.style.layoutPosition = CGPoint(x: 3, y: artSize.height - offlineIndicatorNode.style.preferredSize.height - 3)
        artworkNode.style.layoutPosition = CGPoint(x: 0, y: 0)
        
        let artWithOverlay = ASAbsoluteLayoutSpec(children: ArrayNoNils(artworkNode, soundboardIndicatorNode, isAvailableOffline ? offlineIndicatorNode : nil))
        
        let stack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8.0,
            justifyContent: .start,
            alignItems: .start,
            children: [artWithOverlay, textStack]
        )
        stack.style.alignSelf = .stretch
        
        let s = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(artistNode, stack)
        )
        s.style.alignSelf = .center
        
        // The update date doesn't fit in the current vertical size, and it's not worth changing that size for a property that nobody uses in vertical mode.
        // Uncomment this if that story changes later.
        //            if let updateDateNode = updateDateNode {
        //                verticalStack.append(updateDateNode)
        //            }
        
        let i = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(12, 16, 12, 16),
            child: s
        )
        i.style.alignSelf = .stretch
        
        return i
    }
    
    private func tableLayoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let showAndSBD = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(showNode, soundboardIndicatorNode)
        )
        showAndSBD.style.alignSelf = .stretch
        
        let venueLayout = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(venueNode)
        )
        venueLayout.style.alignSelf = .stretch
        //        venueLayout.style.flexShrink = 1.0
        venueNode.style.flexShrink = 1.0
        //        venueLayout.style.maxWidth = ASDimensionMake(.fraction, 1.0)
        
        let ratingAndMeta = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .end,
            alignItems: .center,
            children: ArrayNoNils(ratingTextNode, SpacerNode(), metaNode)
        )
        ratingAndMeta.style.alignSelf = .stretch
        
        var footer : ASStackLayoutSpec? = nil
        if let updateDateNode = updateDateNode {
            footer = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .end,
                alignItems: .baselineFirst,
                children: ArrayNoNils(updateDateNode)
            )
            footer?.style.alignSelf = .stretch
        }
        
        let textStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(showAndSBD, venueLayout, ratingAndMeta, footer)
        )
        textStack.style.alignSelf = .stretch
        textStack.style.flexShrink = 1.0
        textStack.style.flexGrow = 1.0
        
        let stack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8.0,
            justifyContent: .start,
            alignItems: .start,
            children: [artworkNode, textStack]
        )
        stack.style.alignSelf = .stretch
        stack.style.flexShrink = 1.0
        stack.style.flexGrow = 1.0
        
        //        stack.style.width = ASDimensionMake(.fraction, 1.0)
        
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 8),
            child: stack
        )
        inset.style.alignSelf = .stretch
        inset.style.flexShrink = 1.0
        
        return inset
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if useCellLayout {
            return cellLayoutSpecThatFits(constrainedSize)
        } else {
            return tableLayoutSpecThatFits(constrainedSize)
        }
    }
}
