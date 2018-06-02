//
//  SourceDetailsNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import Observable

public class SourceDetailsNode : ASCellNode {
    public let source: SourceFull
    public let show: ShowWithSources
    public let artist: SlimArtistWithFeatures
    public let index: Int
    public let isDetails: Bool
    
    var disposal = Disposal()
    
    private static func createPrefixedAttributedText(prefix: String, _ text: String?) -> NSAttributedString {
        let mut = NSMutableAttributedString(string: prefix + (text == nil ? "" : text!))
        
        let regularFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
        
        mut.addAttribute(NSAttributedStringKey.font, value: boldFont, range: NSMakeRange(0, prefix.count))
        mut.addAttribute(NSAttributedStringKey.font, value: regularFont, range: NSMakeRange(prefix.count, text == nil ? 0 : text!.count))
        
        return mut
    }
    
    public init(source: SourceFull, inShow show: ShowWithSources, artist: SlimArtistWithFeatures, atIndex: Int, isDetails: Bool) {
        self.source = source
        self.show = show
        self.artist = artist
        self.index = atIndex
        self.isDetails = isDetails
        
        self.showNameNode = ASTextNode(
            isDetails ? (source.venue?.name ?? show.venue?.name ?? "") : "Source \(atIndex + 1) of \(show.sources.count)",
            textStyle: .headline
        )
        self.ratingNode = AXRatingViewNode(value: source.avg_rating / 10.0)
        self.locationNode = ASTextNode(source.venue?.location ?? show.venue?.location ?? "", textStyle: .subheadline, color: UIColor.gray)
        
        var metaText = "\(source.duration == nil ? "" : source.duration!.humanize())"
        
        if isDetails {
            metaText += " • "
            metaText += String(source.num_ratings ?? source.num_reviews) + " "
            metaText += source.num_ratings != nil ? "ratings" : "reviews"
        }
        
        self.metaNode = ASTextNode(metaText, textStyle: .caption1, color: nil, alignment: .right)
        self.ratingCountNode = ASTextNode(
            String(source.num_ratings != nil ? source.num_ratings! : source.num_reviews) + " " + (source.num_ratings != nil ? "ratings" : "reviews"),
            textStyle: .caption1,
            color: nil,
            alignment: .right
        )
        
        if source.is_soundboard {
            sbdNode = SoundboardIndicatorNode()
        }
        else {
            sbdNode = nil
        }
        
        if source.is_remaster {
            remasterNode = RemasterIndicatorNode()
        }
        else {
            remasterNode = nil
        }
        
        if artist.features.source_information {
            if let s = source.source, s.count > 0 {
                sourceNode = ASTextNode()
                sourceNode?.attributedText = SourceDetailsNode.createPrefixedAttributedText(prefix: "Source: ", source.source)
            }
            else {
                sourceNode = nil
            }
            
            if let s = source.lineage, s.count > 0 {
                lineageNode = ASTextNode()
                lineageNode?.attributedText = SourceDetailsNode.createPrefixedAttributedText(prefix: "Lineage: ", source.lineage)
            }
            else {
                lineageNode = nil
            }
            
            if let s = source.taper, s.count > 0 {
                taperNode = ASTextNode()
                taperNode?.attributedText = SourceDetailsNode.createPrefixedAttributedText(prefix: "Taper: ", source.taper)
            }
            else {
                taperNode = nil
            }
        }
        else {
            sourceNode = nil
            lineageNode = nil
            taperNode = nil
        }
        
        detailsNode = ASTextNode("See details, taper notes, reviews & more ›", textStyle: .caption1, color: .gray)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = isDetails ? .none : .disclosureIndicator
        
        if !isDetails {
            let library = MyLibraryManager.shared.library
            library.observeOfflineSources
                .observe({ [weak self] _, _ in
                    guard let s = self else { return }
                    
                    if s.isAvailableOffline != library.isSourceAtLeastPartiallyAvailableOffline(s.source) {
                        s.isAvailableOffline = !s.isAvailableOffline
                        s.setNeedsLayout()
                    }
                })
                .add(to: &disposal)
        }
    }
    
    public let showNameNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    public let ratingCountNode: ASTextNode
    public let locationNode: ASTextNode
    public let metaNode: ASTextNode
    public let detailsNode: ASTextNode
    
    public let sourceNode: ASTextNode?
    public let lineageNode: ASTextNode?
    public let taperNode: ASTextNode?

    public let sbdNode: SoundboardIndicatorNode?
    public let remasterNode: RemasterIndicatorNode?
    
    public let offlineNode = OfflineIndicatorNode()
    public var isAvailableOffline = false
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratingStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .end,
            children: ArrayNoNils(
                isDetails ? nil : ratingCountNode,
                ratingNode
            )
        )
        
        let top = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                isAvailableOffline ? offlineNode : nil,
                showNameNode,
                SpacerNode(),
                isDetails ? nil : sbdNode,
                isDetails ? nil : remasterNode,
                ratingStack
            )
        )
        top.style.alignSelf = .stretch
        
        let second = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(locationNode, SpacerNode(), sbdNode, remasterNode, metaNode)
        )
        second.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                top,
                isDetails ? second : nil,
                sourceNode,
                lineageNode,
                taperNode,
                isDetails ? detailsNode : nil
            )
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(16, 16, 16, isDetails ? 16 : 8),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
