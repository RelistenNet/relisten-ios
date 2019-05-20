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
    public let artist: Artist
    public let index: Int
    public let isDetails: Bool
    private lazy var completeShowInformation = CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)
    
    var disposal = Disposal()
    
    public init(source: SourceFull, inShow show: ShowWithSources, artist: Artist, atIndex: Int, isDetails: Bool) {
        self.source = source
        self.show = show
        self.artist = artist
        self.index = atIndex
        self.isDetails = isDetails
        
        self.showNameNode = ASTextNode(
            isDetails ? (source.venue?.name ?? show.venue?.name ?? "") : "Source \(atIndex + 1) of \(show.sources.count)",
            textStyle: .headline
        )
        
        favoriteButton = FavoriteButtonNode()
        
//        ratingTextNode = (!artist.features.reviews && !artist.features.ratings) ? nil : ASTextNode(String(format: "%.2f ★", source.avg_rating / 10.0 * 5.0), textStyle: .subheadline)
        self.ratingNode = AXRatingViewNode(value: source.avg_rating / 10.0)
        self.locationNode = ASTextNode(source.venue?.location ?? show.venue?.location ?? "", textStyle: .subheadline, color: AppColors.mutedText)
        
        var metaText = "\(source.duration == nil ? "" : source.duration!.humanize())"
        
        if isDetails, (artist.features.reviews || artist.features.ratings) {
            metaText += " • "
            metaText += String(source.num_ratings ?? source.num_reviews) + " "
            metaText += source.num_ratings != nil ? "ratings" : "reviews"
        }
        
        self.metaNode = ASTextNode(metaText, textStyle: .caption1, color: nil, alignment: .right)
        /*
        self.ratingCountNode = ASTextNode(
            String(source.num_ratings != nil ? source.num_ratings! : source.num_reviews) + " " + (source.num_ratings != nil ? "ratings" : "reviews"),
            textStyle: .caption1,
            color: nil,
            alignment: .right
        )
         */
        
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
            taperInfoNode = TaperInfoNode(source: source)
        }
        else {
            taperInfoNode = nil
        }
        
        detailsNode = ASTextNode("See details, taper notes, reviews & more ›", textStyle: .caption1, color: AppColors.mutedText)
        
        let updateDate = DateFormatter.localizedString(from: source.updated_at, dateStyle: .long, timeStyle: .none)
        let updateDateText = "Updated " + updateDate
        updateDateNode = ASTextNode(updateDateText, textStyle: .footnote, color: AppColors.mutedText)
        
        artworkNode = ASImageNode()
        artworkNode.style.maxWidth = .init(unit: .points, value: 100.0)
        artworkNode.style.maxHeight = .init(unit: .points, value: 100.0)
        artworkNode.backgroundColor = show.fastImageCacheWrapper().placeholderColor()
        
        super.init()
        
        self.accessibilityLabel = "Source"
        
        automaticallyManagesSubnodes = true
        accessoryType = isDetails ? .none : .disclosureIndicator
        favoriteButton.delegate = self
        accessibilityLabel = "Source Details"
        
        if !isDetails {
            DispatchQueue.main.async {
                self.favoriteButton.currentlyFavorited = MyLibrary.shared.isFavorite(show: show, byArtist: artist)
                self.favoriteButton.isUserInteractionEnabled = false
                self.favoriteButton.normalColor = UIColor.black
                self.setupNonDetailObservers()
            }
        }
        
        AlbumArtImageCache.shared.cache.asynchronouslyRetrieveImage(for: show.fastImageCacheWrapper(), withFormatName: AlbumArtImageCache.imageFormatSmall) { [weak self] (_, _, i) in
            guard let s = self else { return }
            guard let image = i else { return }
            s.artworkNode.image = image
            s.setNeedsLayout()
        }
    }
    
    private func setupNonDetailObservers() {
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
        
        library.favorites.sources.observeWithValue { [weak self] (new, changes) in
            guard let s = self else { return }
            
            s.favoriteButton.currentlyFavorited = library.isFavorite(source: s.source)
        }.dispose(to: &disposal)
    }
    
    public let showNameNode: ASTextNode
    public let favoriteButton : FavoriteButtonNode
    public let ratingNode: AXRatingViewNode
//    public let ratingCountNode: ASTextNode
    public let locationNode: ASTextNode
    public let metaNode: ASTextNode
    public let detailsNode: ASTextNode
    public let updateDateNode : ASTextNode
    public let artworkNode: ASImageNode
//    public let ratingTextNode: ASTextNode?
    
    public let taperInfoNode : TaperInfoNode?

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
//                isDetails ? nil : ratingCountNode,
//                ratingTextNode
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
                isDetails ? nil : (self.favoriteButton.currentlyFavorited ? favoriteButton : nil),
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
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: ArrayNoNils(
                    top,
                    second,
                    taperInfoNode,
                    detailsNode
                    )
                )
        } else {
            let updateDate = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                updateDateNode,
                SpacerNode()
                )
            )
            updateDate.style.alignSelf = .stretch
            
            vert = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: ArrayNoNils(
                    top,
                    taperInfoNode,
                    updateDate
                )
            )
        }
        vert?.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: isDetails ? 16 : 8),
            child: vert!
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}

extension SourceDetailsNode : FavoriteButtonDelegate {
    public var favoriteButtonAccessibilityLabel : String { get { return "Favorite Source" } }
    
    public func didFavorite(currentlyFavorited : Bool) {
//        if currentlyFavorited {
//            MyLibrary.shared.favoriteSource(show: self.completeShowInformation)
//        } else {
//            let _ = MyLibrary.shared.unfavoriteSource(show: self.completeShowInformation)
//        }
    }
}
