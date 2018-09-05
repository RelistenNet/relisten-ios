//
//  ReviewLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import AsyncDisplayKit
import AXRatingView

public class ReviewLayout: ASCellNode {
    public static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .long
        
        return d
    }()
    
    public init(review: SourceReview, forArtist artist: Artist) {
        if artist.features.review_titles, let reviewTitle = review.title {
            self.titleNode = ASTextNode(reviewTitle, textStyle: .headline, weight: .Bold)
        } else {
            self.titleNode = nil
        }
        
        if let reviewAuthor = review.author {
            let scale : CGFloat = artist.features.review_titles ? 0.8 : 1.0
            self.authorNode = ASTextNode(reviewAuthor, textStyle: .body, scale: scale, weight: .Bold)
        } else {
            self.authorNode = nil
        }
        
        self.dateNode = ASTextNode(ReviewLayout.dateFormatter.string(from: review.updated_at), textStyle: .caption1)
        
        if artist.features.reviews_have_ratings, let userRating = review.rating {
            self.ratingNode = ASTextNode(String(format: "%.2f ★", Double(userRating) / 10.0 * 5.0), textStyle: .subheadline)
        } else {
            self.ratingNode = nil
        }
        
        self.review = ASTextNode(review.review, textStyle: .body)
        
        super.init()
    }
    
    let titleNode : ASTextNode?
    let authorNode : ASTextNode?
    let dateNode : ASTextNode
    let ratingNode : ASTextNode?
    let review : ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let authorAndDateStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .end,
            children: ArrayNoNils(
                authorNode,
                dateNode
            )
        )
        authorAndDateStack.style.alignSelf = .stretch
        
        let authorAndRatingStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                authorAndDateStack,
                SpacerNode(),
                ratingNode
            )
        )
        authorAndRatingStack.style.alignSelf = .stretch
        
        let reviewStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                titleNode,
                authorAndRatingStack,
                review
            )
        )
        reviewStack.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(12, 16, 12, 16),
            child: reviewStack
        )
        l.style.alignSelf = .stretch

        return l
    }
}
