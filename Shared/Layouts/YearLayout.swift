//
// Created by Alec Gorge on 5/31/17.
// Copyright (c) 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

public class YearLayout : InsetLayout<UIView> {
    internal static var ratingViewStub: AXRatingView? = nil

    internal static func ratingSize() -> CGSize {
        if ratingViewStub == nil {
            let r = AXRatingView()
            r.isUserInteractionEnabled = false
            r.value = 0.5
            r.sizeToFit()

            ratingViewStub = r
        }

        if let r = ratingViewStub {
            return r.bounds.size
        }

        return CGSize.zero
    }

    public init(year: Year) {
        let yearName = LabelLayout(
            text: year.year,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "yearName"
        )

        let ratingView = SizeLayout<AXRatingView>(
            width: YearLayout.ratingSize().width,
            height: YearLayout.ratingSize().height,
            alignment: .centerTrailing,
            flexibility: .flexible,
            viewReuseId: "yearRating")
        { (rating: AXRatingView) in
            rating.isUserInteractionEnabled = false
            rating.value = year.avg_rating / 10.0 * 5.0
        }

        let showsLabel = LabelLayout(
            text: "\(year.show_count) shows",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerLeading,
            viewReuseId: "showCount"
        )

        let sourcesLabel = LabelLayout(
            text: "\(year.source_count) recordings",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerTrailing,
            viewReuseId: "sourcesCount"
        )

        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 12, right: 16 + 8 + 8),
            viewReuseId: "yearLayout",
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 4,
                sublayouts: [
                    StackLayout(
                        axis: .horizontal,
                        sublayouts: [
                            yearName,
                            ratingView
                        ]
                    ),
                    StackLayout(
                        axis: .horizontal,
                        sublayouts: [
                            showsLabel,
                            sourcesLabel
                        ]
                    )
                ]
            )
        )
    }
}
