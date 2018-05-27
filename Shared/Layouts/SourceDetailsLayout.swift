//
//  SourceDetailsLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 6/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

public class SourceDetailsLayout : InsetLayout<UIView> {
    private static func createPrefixedAttributedText(prefix: String, _ text: String?) -> NSAttributedString {
        let mut = NSMutableAttributedString(string: prefix + (text == nil ? "" : text!))
        
        let regularFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
        
        mut.addAttribute(NSAttributedStringKey.font, value: boldFont, range: NSMakeRange(0, prefix.count))
        mut.addAttribute(NSAttributedStringKey.font, value: regularFont, range: NSMakeRange(prefix.count, text == nil ? 0 : text!.count))
        
        return mut
    }
    
    public init(source: SourceFull, inShow show: ShowWithSources, artist: SlimArtistWithFeatures, atIndex: Int) {
        var stack : [Layout] = []
        
        if artist.features.per_show_venues || artist.features.per_source_venues {
            let showName = LabelLayout(
                text: source.venue?.name ?? show.venue?.name ?? "",
                font: UIFont.preferredFont(forTextStyle: .headline),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .low,
                viewReuseId: "sourceNumber"
            )
            
            var topRow: [ Layout ] = [ showName ]
            
            let ratingView = SizeLayout<AXRatingView>(
                width: YearLayout.ratingSize().width,
                height: YearLayout.ratingSize().height,
                alignment: .centerTrailing,
                flexibility: .inflexible,
                viewReuseId: "sourceRating")
            { (rating: AXRatingView) in
                rating.isUserInteractionEnabled = false
                rating.value = source.avg_rating / 10.0 * 5.0
            }
            
            topRow.append(ratingView)
            
            stack.append(StackLayout(
                axis: .horizontal,
                spacing: 8.0,
                viewReuseId: "topRow",
                sublayouts: topRow
            ))
            
            var secondRow: [Layout] = []
            
            let location = LabelLayout(
                text: source.venue?.location ?? show.venue?.location ?? "",
                font: UIFont.preferredFont(forTextStyle: .subheadline),
                numberOfLines: 1,
                alignment: .fillLeading,
                flexibility: .flexible,
                viewReuseId: "venueLocation"
            ) { (label) in label.textColor = UIColor.gray }
            
            secondRow.append(location)
            
            if source.is_soundboard {
                secondRow.append(SBDLabelLayout())
            }
            
            if source.is_remaster {
                secondRow.append(RemasterLabelLayout())
            }
            
            let duration = LabelLayout(
                text: "\(source.duration == nil ? "" : source.duration!.humanize()) • " + String(source.num_ratings ?? source.num_reviews) + " " + (source.num_ratings != nil ? "ratings" : "reviews"),
                font: UIFont.preferredFont(forTextStyle: .caption1),
                numberOfLines: 0,
                alignment: .centerTrailing,
                flexibility: .inflexible,
                viewReuseId: "duration"
            ) { (label: UILabel) in
                label.textAlignment = .right
            }
            
            secondRow.append(duration)
            
            stack.append(StackLayout(
                axis: .horizontal,
                spacing: 8.0,
                viewReuseId: "secondRow",
                sublayouts: secondRow
            ))
        }
        else
        {
            // todo
        }
        
        if artist.features.source_information {
            let sourceLayout = LabelLayout(
                attributedText: SourceLayout.createPrefixedAttributedText(prefix: "Source: ", source.source),
                font: UIFont.preferredFont(forTextStyle: .subheadline),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .flexible,
                viewReuseId: "sourceInfo")
            
            let lineageLayout = LabelLayout(
                attributedText: SourceLayout.createPrefixedAttributedText(prefix: "Lineage: ", source.lineage),
                font: UIFont.preferredFont(forTextStyle: .subheadline),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .flexible,
                viewReuseId: "lineageInfo")
            
            let taperLayout = LabelLayout(
                attributedText: SourceLayout.createPrefixedAttributedText(prefix: "Taper: ", source.taper),
                font: UIFont.preferredFont(forTextStyle: .subheadline),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .flexible,
                viewReuseId: "taperInfo")
            
            if let s = source.source, s.count > 0 {
                stack.append(sourceLayout)
            }
            
            if let s = source.lineage, s.count > 0 {
                stack.append(lineageLayout)
            }
            
            if let s = source.taper, s.count > 0 {
                stack.append(taperLayout)
            }
        }
        
        let details = LabelLayout(
            text: "See Details ›",
            font: UIFont.preferredFont(forTextStyle: .caption1),
            numberOfLines: 1,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "seeDetails"
        ) { (label) in label.textColor = UIColor.gray }
        
        stack.append(details)

        super.init(
            insets: EdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            viewReuseId: "sourceDetailsLayout",
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 8,
                sublayouts: stack
            )
        )
    }
}

