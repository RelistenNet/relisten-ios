//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

import AsyncDisplayKit
import Observable

public class YearShowCellNode : ASCellNode {
    public let show: Show
    public let artist: SlimArtist?
    public let rank: Int?
    public let vertical: Bool
    
    var disposal = Disposal()
    
    public init(show: Show, withRank: Int? = nil, verticalLayout: Bool = false, showingArtist: SlimArtist? = nil, showUpdateDate : Bool = false, cellTransparency : CGFloat = 1.0) {
        self.show = show
        artist = showingArtist
        rank = withRank
        vertical = verticalLayout
        
        if let artist = showingArtist {
            artistNode = ASTextNode(artist.name, textStyle: .caption1, color: AppColors.mutedText)
        }
        else {
            artistNode = nil
        }
        
        showNode = ASTextNode(show.display_date, textStyle: .headline)
        
        var venueText = " \n "
        if let v = show.venue {
            venueText = "\(v.name)\n\(v.location)"
        }
        
        venueNode = ASTextNode(venueText, textStyle: .caption1)
        ratingNode = AXRatingViewNode(value: show.avg_rating / 10.0)
        
        var metaText = "\(show.avg_duration == nil ? "" : show.avg_duration!.humanize())"
        if !verticalLayout {
            metaText += "\n\(show.source_count) recordings"
        }
        
        metaNode = ASTextNode(metaText, textStyle: .caption1, color: nil, alignment: vertical ? nil : NSTextAlignment.right)
        
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
            soundboardIndicatorNode = SoundboardIndicatorNode()
        }
        else {
            soundboardIndicatorNode = nil
        }
        
        isAvailableOffline = MyLibrary.shared.isShowAtLeastPartiallyAvailableOffline(self.show)
        
        super.init()
        
        if cellTransparency == 1.0 {
            self.backgroundColor = UIColor.white
        } else if cellTransparency == 0.0 {
            self.backgroundColor = UIColor.clear
        } else {
            self.backgroundColor = UIColor(white: 1.0, alpha: cellTransparency)
        }
        
        automaticallyManagesSubnodes = true
        
        if verticalLayout {
            borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
            borderWidth = 1.0
            cornerRadius = 3.0
        }
        else {
            accessoryType = .disclosureIndicator
        }
    }
    
    public let artistNode: ASTextNode?
    public let showNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    
    public let venueNode: ASTextNode
    public let metaNode: ASTextNode
    public let updateDateNode : ASTextNode?
    
    public let rankNode: ASTextNode?
    public let offlineIndicatorNode = OfflineIndicatorNode()
    public let soundboardIndicatorNode: SoundboardIndicatorNode?
    
    var isAvailableOffline = false
    
    public override func didLoad() {
        super.didLoad()
        
        let library = MyLibrary.shared
        
        library.offline.sources.observe { [weak self] (changes) in
            guard let s = self else { return }

            if s.isAvailableOffline != library.isShowAtLeastPartiallyAvailableOffline(s.show) {
                s.isAvailableOffline = !s.isAvailableOffline
                s.setNeedsLayout()
            }
        }.dispose(to: &disposal)
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if vertical {
            var verticalStack: [ASLayoutElement] = []
            
            if let art = artistNode {
                verticalStack.append(art)
            }
            
            verticalStack.append(contentsOf: [
                showNode,
                venueNode,
                ratingNode
            ])
            
            var metaStack: [ASLayoutElement] = []

            if isAvailableOffline {
                metaStack.append(offlineIndicatorNode)
            }
            
            if let sbd = soundboardIndicatorNode {
                metaStack.append(sbd)
            }
            
            metaStack.append(metaNode)
            
            let vs = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: metaStack
            )
            vs.style.minHeight = .init(unit: .points, value: 22.0)
            
            verticalStack.append(vs)
            
            // The update date doesn't fit in the current vertical size, and it's not worth changing that size for a property that nobody uses in vertical mode.
            // Uncomment this if that story changes later.
//            if let updateDateNode = updateDateNode {
//                verticalStack.append(updateDateNode)
//            }
            
            return ASInsetLayoutSpec(
                insets: UIEdgeInsetsMake(12, 12, 12, 12),
                child: ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 4,
                    justifyContent: .start,
                    alignItems: .start,
                    children: verticalStack
                )
            )
        }
        
        let top = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(showNode, soundboardIndicatorNode, SpacerNode(), ratingNode)
        )
        top.style.alignSelf = .stretch
        
        let bottom = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .spaceBetween,
            alignItems: .baselineFirst,
            children: ArrayNoNils(venueNode, metaNode)
        )
        bottom.style.alignSelf = .stretch
        
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
        
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(top, bottom, footer)
        )
        stack.style.alignSelf = .stretch

        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 8),
            child: stack
        )
        inset.style.alignSelf = .stretch
        
        return inset
        
    }
}
