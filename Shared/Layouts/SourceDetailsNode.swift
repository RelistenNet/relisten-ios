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
            var taperName : String? = nil
            var transferrerName : String? = nil
            
            var taperNode : ASTextNode? = nil
            var transferrerNode : ASTextNode? = nil
            
            var sourcePeople : [ASTextNode] = []
            
            if let s = source.taper, s.count > 0 {
                taperName = s
                
                taperNode = ASTextNode()
                taperNode?.attributedText = String.createPrefixedAttributedText(prefix: "Taper: ", taperName)
            }
            
            if let s = source.transferrer, s.count > 0 {
                transferrerName = s
                
                transferrerNode = ASTextNode()
                transferrerNode?.attributedText = String.createPrefixedAttributedText(prefix: "Transferrer: ", transferrerName)
            }
            
            if let taperNode = taperNode {
                sourcePeople.append(taperNode)
            }
            
            if let transferrerNode = transferrerNode, transferrerName != taperName {
                sourcePeople.append(transferrerNode)
            }
            
            sourcePeopleNode = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: sourcePeople
            )
            sourcePeopleNode?.flexWrap = .wrap
            
            if let s = source.source, s.count > 0 {
                sourceNode = ASTextNode()
                sourceNode?.attributedText = String.createPrefixedAttributedText(prefix: "Source: ", source.source)
            }
            else {
                sourceNode = nil
            }
        }
        else {
            sourceNode = nil
            sourcePeopleNode = nil
        }
        
        detailsNode = ASTextNode("See details, taper notes, reviews & more ›", textStyle: .caption1, color: .gray)
        
        artworkNode = ASImageNode()
        artworkNode.style.maxWidth = .init(unit: .points, value: 100.0)
        artworkNode.style.maxHeight = .init(unit: .points, value: 100.0)
        artworkNode.backgroundColor = show.fastImageCacheWrapper().placeholderColor()
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = isDetails ? .none : .disclosureIndicator
        
        if !isDetails {
            DispatchQueue.main.async {
                let library = MyLibrary.shared
                library.offline.sources
                    .observeWithValue({ [weak self] _, _ in
                        guard let s = self else { return }
                        
                        if s.isAvailableOffline != library.isSourceAtLeastPartiallyAvailableOffline(s.source) {
                            s.isAvailableOffline = !s.isAvailableOffline
                            s.setNeedsLayout()
                        }
                    })
                    .dispose(to: &self.disposal)
            }
        }
        
        AlbumArtImageCache.shared.cache.asynchronouslyRetrieveImage(for: show.fastImageCacheWrapper(), withFormatName: AlbumArtImageCache.imageFormatSmall) { [weak self] (_, _, i) in
            guard let s = self else { return }
            guard let image = i else { return }
            s.artworkNode.image = image
            s.setNeedsLayout()
        }
    }
    
    public let showNameNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    public let ratingCountNode: ASTextNode
    public let locationNode: ASTextNode
    public let metaNode: ASTextNode
    public let detailsNode: ASTextNode
    public let artworkNode: ASImageNode
    
    public let sourcePeopleNode: ASStackLayoutSpec?
    public let sourceNode: ASTextNode?

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
        
        showNameNode.style.flexShrink = 0.5
        
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
            children: ArrayNoNils(
                locationNode,
                SpacerNode(),
                sbdNode,
                remasterNode,
                metaNode)
        )
        second.style.alignSelf = .stretch
        
        var vert : ASStackLayoutSpec? = nil
        if isDetails {
                vert = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .start,
                children: ArrayNoNils(
                    top,
                    second,
                    sourcePeopleNode,
                    sourceNode,
                    detailsNode
                    )
                )
        } else {
            vert = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .start,
                children: ArrayNoNils(
                    top,
                    sourcePeopleNode,
                    sourceNode
                )
            )
        }
        vert?.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(16, 16, 16, isDetails ? 16 : 8),
            child: vert!
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
