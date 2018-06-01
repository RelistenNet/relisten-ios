//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

import AsyncDisplayKit
import Observable

public func SBDLabelLayout() -> InsetLayout<UIView> {
    let sbd = LabelLayout(
        text: "SBD",
        font: UIFont.preferredFont(forTextStyle: .subheadline),
        numberOfLines: 0,
        alignment: .fill,
        flexibility: .inflexible,
        viewReuseId: "sbdLabel")
    { (lbl: UILabel) in
        lbl.textColor = UIColor.white
    }
    
    let layout = InsetLayout(
        inset: 2.0,
        alignment: .centerTrailing,
        viewReuseId: "sbdInset",
        sublayout: sbd
    ) { (view: UIView) in
        view.backgroundColor = AppColors.soundboard
    }
    
    return layout
}

public func RemasterLabelLayout() -> InsetLayout<UIView> {
    let sbd = LabelLayout(
        text: "Remaster",
        font: UIFont.preferredFont(forTextStyle: .subheadline),
        numberOfLines: 0,
        alignment: .fill,
        flexibility: .flexible,
        viewReuseId: "remasterLabel")
    { (lbl: UILabel) in
        lbl.textColor = UIColor.white
    }
    
    let layout = InsetLayout(
        inset: 2.0,
        alignment: .centerTrailing,
        viewReuseId: "remasterInset",
        sublayout: sbd
    ) { (view: UIView) in
        view.backgroundColor = AppColors.remaster
    }
    
    return layout
}

public class CollectionViewLayout : SizeLayout<UICollectionView> {
    public var collectionViewLayout: UICollectionViewLayout! = nil
    
    public override func makeView() -> View {
        return UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
    }
}

public class CellSelectCallbackReloadableViewLayoutAdapter : ReloadableViewLayoutAdapter {
    let callback: (IndexPath) -> Bool
    
    public init(reloadableView: ReloadableView, _ callback: @escaping (IndexPath) -> Bool) {
        self.callback = callback

        super.init(reloadableView: reloadableView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.callback(indexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
}

public func HorizontalShowCollection(withId: String, makeAdapater cb: @escaping (UICollectionView) -> ReloadableViewLayoutAdapter, layoutProvider: @escaping () -> [Section<[Layout]>]) -> CollectionViewLayout {
    let l = CollectionViewLayout(
        minHeight: 165,
        alignment: .fill,
        flexibility: .flexible,
        viewReuseId: "horizShowCollection-" + withId,
        config: { (collectionView) in
            DispatchQueue.main.async {
                let adapter = cb(collectionView)
                
                collectionView.backgroundColor = UIColor.clear
                collectionView.delegate = adapter
                collectionView.dataSource = adapter
                //            collectionView.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)

                adapter.reload(width: nil, synchronous: true, layoutProvider: layoutProvider)
            }
    })
    
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 4, 4)
    flowLayout.estimatedItemSize = CGSize(width: 170, height: 145)
    flowLayout.minimumInteritemSpacing = 16
    
    l.collectionViewLayout = flowLayout
    
    return l
}

public class HorizontalShowCollectionCellNode : ASCellNode, ASCollectionDataSource {
    public let collectionNode: ASCollectionNode
    
    var disposal = Disposal()
    
    public var shows: [(show: Show, artist: ArtistWithCounts?)] {
        didSet {
            collectionNode.reloadData()
        }
    }
    
    public init(forShows shows: [(show: Show, artist: ArtistWithCounts?)], delegate: ASCollectionDelegate?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 16
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 170, height: 145)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 4, 4)

        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        self.shows = shows
        
        super.init()
        
        collectionNode.dataSource = self
        collectionNode.delegate = delegate
        collectionNode.setNeedsLayout()

        automaticallyManagesSubnodes = true
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.alignSelf = .stretch
        collectionNode.style.preferredLayoutSize = ASLayoutSizeMake(.init(unit: .fraction, value: 1.0), .init(unit: .points, value: 165))
        
        let l = ASAbsoluteLayoutSpec(sizing: .default, children: [collectionNode])
        l.style.minHeight = .init(unit: .points, value: 165)
        
        return l
    }
    
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return shows.count > 0 ? 1 : 0
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return shows.count
    }
    
    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let show = shows[indexPath.row]
        
        return { YearShowCellNode(show: show.show, withRank: nil, verticalLayout: true, showingArtist: show.artist) }
    }
}

public class AXRatingViewNode : ASDisplayNode {
    public let value: Float
    
    public init(value: Float) {
        self.value = value

        ratingViewNode = ASDisplayNode(viewBlock: {
            let a = AXRatingView()
            a.sizeToFit()
            return a
        })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    public let ratingViewNode: ASDisplayNode
    public var fixedSize = RatingViewStubBounds.size
    
    public override func didLoad() {
        if let ax = ratingViewNode.view as? AXRatingView {
            ax.isUserInteractionEnabled = false
            ax.value = value * 5.0
        }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ratingViewNode.style.minSize = fixedSize
        
        let l = ASWrapperLayoutSpec(layoutElement: ratingViewNode)
        l.style.minSize = fixedSize
        
        return l
    }
}

public let OfflineIndicatorImage = UIImage(named: "download-complete")!

public class OfflineIndicatorNode : ASImageNode {
    public override init() {
        super.init()
        
        image = OfflineIndicatorImage
        contentMode = .scaleAspectFit
        style.preferredSize = CGSize(width: 12, height: 12)
        automaticallyManagesSubnodes = true
    }
}

public class SoundboardIndicatorNode: ASDisplayNode {
    public override init() {
        sbdNode = ASTextNode("SBD", textStyle: .subheadline, color: AppColors.textOnPrimary)
        
        super.init()
        
        backgroundColor = AppColors.soundboard
        automaticallyManagesSubnodes = true
    }
    
    let sbdNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(2, 2, 2, 2), child: sbdNode)
    }
}

public func ArrayNoNils<T>(_ values: T?...) -> [T] {
    return values.filter({ $0 != nil }) as! [T]
}

public class YearShowCellNode : ASCellNode {
    public let show: Show
    public let artist: SlimArtist?
    public let rank: Int?
    public let vertical: Bool
    
    var disposal = Disposal()
    
    public convenience init(show: Show) {
        self.init(show: show, withRank: nil, verticalLayout: false, showingArtist: nil)
    }
    
    public init(show: Show, withRank: Int?, verticalLayout: Bool, showingArtist: SlimArtist? = nil) {
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
        
        isAvailableOffline = MyLibraryManager.shared.library.isShowAtLeastPartiallyAvailableOffline(self.show)
        
        super.init()
        
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
    public let venueNode: ASTextNode
    public let ratingNode: AXRatingViewNode
    public let metaNode: ASTextNode
    
    public let rankNode: ASTextNode?
    public let offlineIndicatorNode = OfflineIndicatorNode()
    public let soundboardIndicatorNode: SoundboardIndicatorNode?
    
    var isAvailableOffline = false
    
    public override func didLoad() {
        super.didLoad()
        
        let library = MyLibraryManager.shared.library
        library.observeOfflineSources
            .observe({ [weak self] _, _ in
                guard let s = self else { return }
                
                s.isAvailableOffline = library.isShowAtLeastPartiallyAvailableOffline(s.show)
                s.setNeedsLayout()
            })
            .add(to: &disposal)
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
        
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4.0,
            justifyContent: .start,
            alignItems: .start,
            children: [top, bottom]
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

public class YearShowLayout : InsetLayout<UIView> {
    public convenience init(show: Show) {
        self.init(show: show, withRank: nil, verticalLayout: false, showingArtist: nil)
    }
    
    public init(show: Show, withRank: Int?, verticalLayout: Bool, showingArtist: SlimArtist? = nil) {
        let showName = LabelLayout(
            text: show.display_date,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "showName"
        )

        let ratingView = SizeLayout<AXRatingView>(
                width: RatingViewStubBounds.size.width,
                height: RatingViewStubBounds.size.height,
                alignment: verticalLayout ? .centerLeading : .centerTrailing,
                flexibility: .flexible,
                viewReuseId: "yearRating")
        { (rating: AXRatingView) in
            rating.isUserInteractionEnabled = false
            rating.value = show.avg_rating / 10.0 * 5.0
        }

        var venueText = " \n "
        if let v = show.venue {
            venueText = "\(v.name)\n\(v.location)"
        }
        
        let venueLabel = LabelLayout(
            text: venueText,
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 0,
            alignment: .centerLeading,
            viewReuseId: "showCount"
        )

        var metaText = "\(show.avg_duration == nil ? "" : show.avg_duration!.humanize())"
        if !verticalLayout {
            metaText += "\n\(show.source_count) recordings"
        }
        
        let metaLabel = LabelLayout(
            text: metaText,
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 0,
            alignment: verticalLayout ? .centerLeading : .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "sourcesCount"
        ) { (label: UILabel) in
            label.textAlignment = verticalLayout ? .left : .right
        }
        
        let rankLabel = LabelLayout(
            text: withRank == nil ? "" : "#\(withRank!)",
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 1,
            alignment: .center,
            flexibility: .inflexible,
            viewReuseId: "rankLabel"
        ) { (label: UILabel) in
            label.textColor = AppColors.mutedText
        }

        var topRow: [ Layout ] = [ showName ]

        if(show.has_soundboard_source) {
            topRow.append(SBDLabelLayout())
        }
        
        topRow.append(ratingView)
        
        let hasOffline = MyLibraryManager.shared.library.isShowAtLeastPartiallyAvailableOffline(show)
        
        let offlineIndicator = SizeLayout<UIImageView>(
            minWidth: 12,
            maxWidth: nil,
            minHeight: 12,
            maxHeight: nil,
            alignment: Alignment.center,
            flexibility: Flexibility.inflexible,
            viewReuseId: "offlineIndicator",
            sublayout: nil,
            config: { imageV in
                imageV.image = UIImage(named: "download-complete")
        })
        
        if verticalLayout {
            var fullStackLayouts: [Layout] = [ showName, venueLabel ]
            
            if let artist = showingArtist {
                let artistLabel = LabelLayout(
                    text: artist.name,
                    font: UIFont.preferredFont(forTextStyle: .caption1),
                    numberOfLines: 1,
                    alignment: .centerLeading,
                    flexibility: .inflexible,
                    viewReuseId: "artistLabel"
                ) { (label: UILabel) in
                    label.textColor = AppColors.mutedText
                }
                
                fullStackLayouts.insert(artistLabel, at: 0)
            }
            
            var metaStack: [Layout] = []
            
            if hasOffline {
                metaStack.append(offlineIndicator)
            }
            
            if show.has_soundboard_source {
                metaStack.append(SBDLabelLayout())
            }

            metaStack.append(metaLabel)
            
            fullStackLayouts.append(ratingView)
            
            fullStackLayouts.append(SizeLayout<UIView>(
                minHeight: 22,
                sublayout: StackLayout(
                    axis: .horizontal,
                    spacing: 8,
                    sublayouts: metaStack
                )
            ))
            
            let fullStack = StackLayout(
                axis: .vertical,
                spacing: 4,
                sublayouts: fullStackLayouts
            )
            
            super.init(
                insets: EdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
                viewReuseId: "yearShowLayoutVertical",
                sublayout: fullStack,
                config: { view in
                    view.backgroundColor = UIColor.white
                }
            )
        }
        else {
            let showStack = StackLayout(
                axis: .vertical,
                spacing: 4,
                sublayouts: [
                    StackLayout(
                        axis: .horizontal,
                        spacing: 8,
                        sublayouts: topRow
                    ),
                    StackLayout(
                        axis: .horizontal,
                        spacing: 8,
                        sublayouts: hasOffline ? [
                            offlineIndicator,
                            venueLabel,
                            metaLabel
                            ] : [
                                venueLabel,
                                metaLabel
                        ]
                    )
                ]
            )
            
            let rankStack = StackLayout(
                axis: .horizontal,
                spacing: 4,
                sublayouts: [
                    InsetLayout(inset: 12.0, sublayout: rankLabel),
                    showStack
                ]
            )
            
            super.init(
                insets: EdgeInsets(top: 8, left: withRank == nil ? 16 : 0, bottom: 12, right: 16 + 8 + 8),
                viewReuseId: "yearShowLayout",
                sublayout: withRank == nil ? showStack : rankStack
            )
        }
    }
}
