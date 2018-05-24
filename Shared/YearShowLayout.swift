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

public class YearShowLayout : InsetLayout<UIView> {
    public convenience init(show: Show) {
        self.init(show: show, withRank: nil)
    }
    
    public init(show: Show, withRank: Int?) {
        let showName = LabelLayout(
            text: show.display_date,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "showName"
        )

        let ratingView = SizeLayout<AXRatingView>(
                width: YearLayout.ratingSize().width,
                height: YearLayout.ratingSize().height,
                alignment: .centerTrailing,
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

        let metaLabel = LabelLayout(
            text: "\(show.avg_duration == nil ? "" : show.avg_duration!.humanize())\n\(show.source_count) recordings",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 0,
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "sourcesCount"
        ) { (label: UILabel) in
            label.textAlignment = .right
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
