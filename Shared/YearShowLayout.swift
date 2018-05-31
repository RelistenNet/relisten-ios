//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

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
