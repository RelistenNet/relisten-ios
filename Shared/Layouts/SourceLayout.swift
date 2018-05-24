//
//  Source.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import AXRatingView

public class SourceLayout : InsetLayout<UIView> {
    internal static func createPrefixedAttributedText(prefix: String, _ text: String?) -> NSAttributedString {
        let mut = NSMutableAttributedString(string: prefix + (text == nil ? "" : text!))
        
        let regularFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
        
        mut.addAttribute(NSAttributedStringKey.font, value: boldFont, range: NSMakeRange(0, prefix.count))
        mut.addAttribute(NSAttributedStringKey.font, value: regularFont, range: NSMakeRange(prefix.count, text == nil ? 0 : text!.count))
        
        return mut
    }
    
    public init(source: SourceFull, idx: Int, sourceCount: Int) {
        let showName = LabelLayout(
            text: "Source \(idx + 1) of \(sourceCount)",
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .centerLeading,
            flexibility: .low,
            viewReuseId: "sourceNumber"
        )
        
        var topRow: [ Layout ] = [ showName ]
        
        if MyLibraryManager.shared.library.isSourceAtLeastPartiallyAvailableOffline(source) {
            topRow.insert(
                InsetLayout(
                    insets: UIEdgeInsetsMake(0, 0, 0, 4),
                    sublayout: RelistenMakeOfflineExistsIndicator()
                ),
                at: 0
            )
        }
        
        if source.is_soundboard {
            topRow.append(SBDLabelLayout())
        }
        
        if source.is_remaster {
            topRow.append(RemasterLabelLayout())
        }
        
        let ratingNumber = LabelLayout(
            text: String(source.num_ratings != nil ? source.num_ratings! : source.num_reviews) + " " + (source.num_ratings != nil ? "ratings" : "reviews"),
            font: UIFont.preferredFont(forTextStyle: .subheadline),
            numberOfLines: 1,
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "sourceRatingNumber"
        ) { (label) in label.textAlignment = .right }
        
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
        
        topRow.append(StackLayout(
            axis: .vertical,
            spacing: 4,
            sublayouts: [
                ratingNumber,
                ratingView
            ])
        )
        
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
        
        _ = ButtonLayout(
            type: .custom,
            title: "🎧 Listen to this source →",
            image: .defaultImage,
            font: UIFont.preferredFont(forTextStyle: .headline),
            contentEdgeInsets: UIEdgeInsetsMake(16, 16, 16, 16),
            alignment: .fill,
            flexibility: .flexible,
            viewReuseId: "listenButton") { (button) in
                button.backgroundColor = AppColors.remaster
                button.setTitleColor(AppColors.textOnPrimary, for: .normal)
        }
        
        var subLayouts: [Layout] = [
            StackLayout(
                axis: .horizontal,
                spacing: 4,
                sublayouts: topRow
            ),
        ]
        
        func isStringEmptyOrNil(_ str: String?) -> Bool {
            return str == nil || str?.count == 0
        }
        
        if !isStringEmptyOrNil(source.source) {
            subLayouts.append(sourceLayout)
        }
        
        if !isStringEmptyOrNil(source.lineage) {
            subLayouts.append(lineageLayout)
        }
        
        if !isStringEmptyOrNil(source.taper) {
            subLayouts.append(taperLayout)
        }

        super.init(
            insets: EdgeInsets(top: 16, left: 16, bottom: 16, right: 16 + 8 + 8),
            viewReuseId: "sourceLayout",
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 8,
                sublayouts: subLayouts
            )
        )
    }
}

