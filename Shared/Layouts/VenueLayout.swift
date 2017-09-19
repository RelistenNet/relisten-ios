//
//  VenueLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 9/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import LayoutKit
import AXRatingView

extension Numeric {
    public func pluralize(_ single: String, _ multiple: String) -> String {
        if(self == 1) {
            return "\(self) \(single)"
        }
        
        return "\(self) \(multiple)"
    }
}

public class VenueLayout : InsetLayout<UIView> {
    public init(venue: VenueWithShowCount) {
        let venueName = LabelLayout(
            text: venue.name,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "venueName"
        )
        
        let venuePastNames = LabelLayout(
            text: venue.past_names == nil ? "" : venue.past_names!,
            font: UIFont.preferredFont(forTextStyle: .subheadline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "venuePastNames"
        )
        
        let venueLocation = LabelLayout(
            text: venue.location,
            font: UIFont.preferredFont(forTextStyle: .subheadline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "venueLocation"
        )

        let showsLabel = LabelLayout(
            text: venue.shows_at_venue.pluralize("show", "shows"),
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "venueShowCount"
        )
        
        var sb = [venueName]
        
        if(venue.past_names != nil) {
            sb.append(venuePastNames)
        }
        
        sb.append(venueLocation)
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 12, right: 16 + 8 + 8),
            viewReuseId: "venueLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 8,
                sublayouts: [
                    StackLayout(
                        axis: .vertical,
                        sublayouts: sb
                    ),
                    showsLabel
                ]
            )
        )
    }
}
