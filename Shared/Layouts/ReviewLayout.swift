//
//  ReviewLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

public class ReviewLayout: InsetLayout<UIView> {
    public static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .long
        
        return d
    }()
    
    public init(review: SourceReview, forArtist artist: Artist) {
        var verticalStack: [Layout] = []
        
        if artist.features.review_titles {
            let titleLabel = LabelLayout(
                text: review.title ?? "(no title given)",
                font: UIFont.preferredFont(forTextStyle: .headline).font(scaledBy: 1.0, withDifferentWeight: .Bold),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .inflexible,
                viewReuseId: "reviewTitle",
                config: nil
            )
            
            verticalStack.append(titleLabel)
        }
        
        var horizStack: [Layout] = []
        
        let authorLabel = LabelLayout(
            text: review.author ?? "(no author given)",
            font: UIFont.preferredFont(forTextStyle: .body).font(scaledBy: artist.features.review_titles ? 0.8 : 1.0, withDifferentWeight: .Bold),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "reviewAuthor",
            config: nil
        )
        
        let dateLabel = LabelLayout(
            text: ReviewLayout.dateFormatter.string(from: review.updated_at),
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "reviewDate",
            config: nil
        )
        
        horizStack.append(StackLayout(
            axis: .vertical,
            spacing: 4,
            sublayouts: [
                authorLabel,
                dateLabel
            ]
        ))
        
        if artist.features.reviews_have_ratings, let userRating = review.rating {
            let ratingView = SizeLayout<AXRatingView>(
                width: RatingViewStubBounds.size.width,
                height: RatingViewStubBounds.size.height,
                alignment: .centerTrailing,
                flexibility: .inflexible,
                viewReuseId: "sourceRating")
            { (rating: AXRatingView) in
                rating.isUserInteractionEnabled = false
                rating.value = Float(userRating) / 10.0 * 5.0
            }
            
            horizStack.append(ratingView)
        }
        
        verticalStack.append(StackLayout(
            axis: .horizontal,
            sublayouts: horizStack
        ))
        
        /*
        let review = TextViewLayout(
            attributedText: review.review.convertHtml(),
            layoutAlignment: .fillLeading,
            flexibility: .inflexible,
            viewReuseId: "review",
            config: nil
        )
        */
        
        let review = LabelLayout(
            text: review.review,
            font: UIFont.preferredFont(forTextStyle: .body),
            alignment: .fillLeading,
            flexibility: .inflexible,
            viewReuseId: "review",
            config: nil
        )
        
        verticalStack.append(review)
        
        super.init(
            insets: UIEdgeInsetsMake(12, 16, 12, 16),
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 8,
                sublayouts: verticalStack
            )
        )
    }
}
