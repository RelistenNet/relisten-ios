//
//  SourceDetailsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import SafariServices

public class SourceDetailsViewController : RelistenBaseTableViewController {
    let artist: Artist
    let show: ShowWithSources
    let source: SourceFull
    var hasSourceInformation : Bool = false
    
    public required init(artist: Artist, show: ShowWithSources, source: SourceFull) {
        self.artist = artist
        self.show = show
        self.source = source

        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Source Details"
        cellDefaultBackgroundColor = UIColor.white
        
        render()
    }
    
    func buildLayout() -> [Section<[Layout]>] {
        var sections: [Section<[Layout]>] = []
        
        var section: [Layout] = []
        
        let insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 32)
        
        if let venue = show.correctVenue(withFallback: source.venue) {
            section.append(VenueLayoutWithMap(venue: venue, forArtist: artist))
        }
        
        if artist.features.source_information {
            var sourceInfo : [LabelLayout] = [] as! [LabelLayout]
            
            // (Farkas) This spacer is a bad hack, but I figure this code is all getting converted to AsyncDisplayKit soon so I didn't want to waste time finding a better fix
            let spacer = LabelLayout(
                    text: " ",
                    font: UIFont.preferredFont(forTextStyle: .body),
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
            
            if let s = source.taper, s.count > 0 {
                let taperLabel = LabelLayout(
                    attributedText: String.createPrefixedAttributedText(prefix: "Taper: ", s),
                    font: UIFont.preferredFont(forTextStyle: .body),
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
                if sourceInfo.count > 0 {
                    sourceInfo.append(spacer)
                }
                sourceInfo.append(taperLabel)
            }
            
            
            if let s = source.transferrer, s.count > 0 {
                let transferrerLabel = LabelLayout(
                    attributedText: String.createPrefixedAttributedText(prefix: "Transferrer: ", s),
                    font: UIFont.preferredFont(forTextStyle: .body),
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
                if sourceInfo.count > 0 {
                    sourceInfo.append(spacer)
                }
                sourceInfo.append(transferrerLabel)
            }
            
            if let s = source.source, s.count > 0 {
                let sourceLabel = LabelLayout(
                    attributedText: String.createPrefixedAttributedText(prefix: "Source: ", s),
                    font: UIFont.preferredFont(forTextStyle: .body),
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
                if sourceInfo.count > 0 {
                    sourceInfo.append(spacer)
                }
                sourceInfo.append(sourceLabel)
            }
            
            if let s = source.lineage, s.count > 0 {
                let lineageLabel = LabelLayout(
                    attributedText: String.createPrefixedAttributedText(prefix: "Lineage: ", s),
                    font: UIFont.preferredFont(forTextStyle: .body),
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
                if sourceInfo.count > 0 {
                    sourceInfo.append(spacer)
                }
                sourceInfo.append(lineageLabel)
            }
            
            if sourceInfo.count > 0 {
                hasSourceInformation = true
                let stack = StackLayout(
                        axis: .vertical,
                        sublayouts: sourceInfo
                )
                
                section.append(InsetLayout(insets: insets, sublayout: stack))
            }
        }
        
        if artist.features.taper_notes, let notes = source.taper_notes, notes.count > 0 {
            let label = LabelLayout(
                text: "Taper Notes",
                font: UIFont.preferredFont(forTextStyle: .body),
                alignment: .fill,
                flexibility: .inflexible,
                viewReuseId: "text",
                config: nil
            )
            
            section.append(InsetLayout(insets: insets, sublayout: label))
        }
        
        if artist.features.descriptions, let _ = source.description {
            let label = LabelLayout(
                text: "Description / Setlist Notes",
                font: UIFont.preferredFont(forTextStyle: .body),
                alignment: .fill,
                flexibility: .inflexible,
                viewReuseId: "text",
                config: nil
            )
            
            section.append(InsetLayout(insets: insets, sublayout: label))
            
            /*
            let taperNotes = TextViewLayout(
                attributedText: desc.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).convertHtml(),
                layoutAlignment: .fill,
                flexibility: .inflexible,
                viewReuseId: "description",
                config: { textView in
                    textView.dataDetectorTypes = .link
                }
            )
            
            sections.append(LayoutsAsSingleSection(items: [InsetLayout(inset: 16.0, sublayout: taperNotes)], title: "Description / Setlist Notes"))
            */
        }
        
        if artist.features.ratings {
            let label = LabelLayout(
                text: "Ratings",
                font: UIFont.preferredFont(forTextStyle: .body),
                alignment: .centerLeading,
                flexibility: .inflexible,
                viewReuseId: "text",
                config: nil
            )
            
            var baseText = String(format: "%.2f/10.00", source.avg_rating)
            
            if let numRatings = source.num_ratings {
                baseText += String(format: " (%d ratings)", numRatings)
            }
            
            let rating = LabelLayout(
                text: baseText,
                font: UIFont.preferredFont(forTextStyle: .body),
                alignment: .centerTrailing,
                flexibility: .flexible,
                viewReuseId: "pullRight"
            )
            
            section.append(InsetLayout(insets: insets, sublayout: StackLayout(
                axis: .horizontal,
                sublayouts: [label, rating]
            )))
        }
        
        if artist.features.reviews {
            let label = LabelLayout(
                text: source.review_count.pluralize("Review", "Reviews"),
                font: UIFont.preferredFont(forTextStyle: .body),
                alignment: .fill,
                flexibility: .inflexible,
                viewReuseId: "text",
                config: nil
            )
            
            section.append(InsetLayout(insets: insets, sublayout: label))
        }
        
        sections.append(LayoutsAsSingleSection(items: section))
        
        let credits = source.links
            .compactMap({ link -> LinkLayout? in
                if let upstream = artist.upstream_sources.first(where: { $0.upstream_source_id == link.upstream_source_id }),
                   let upstreamSource = upstream.upstream_source {
                    return LinkLayout(link: link, forUpstreamSource: upstreamSource)
                }
                return nil
            })
        
        if credits.count > 0 {
            sections.append(LayoutsAsSingleSection(items: credits, title: "Credits"))
        }
        
        return sections
    }
    
    public override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cell: cell, forRowAt: indexPath)
        
        if !(hasSourceInformation && indexPath.row == 1) {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if hasSourceInformation, indexPath.row == 1 {
            return false
        }
        return true
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            var matchingRows = 0
            
            if let venue = show.correctVenue(withFallback: source.venue) {
                if indexPath.row == matchingRows {
                    navigationController?.pushViewController(VenueViewController(artist: artist, venue: venue), animated: true)
                    
                    return
                }
            }
            
            if hasSourceInformation {
                matchingRows += 1
            }
            
            if artist.features.taper_notes, let notes = source.taper_notes, notes.count > 0 {
                matchingRows += 1
                
                if indexPath.row == matchingRows {
                    let vc = LongTextViewController(text: notes, withFont: UIFont(name: "Courier", size: 14.0)!)
                    vc.title = "Taper Notes"
                    
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            if artist.features.descriptions, let desc = source.description {
                matchingRows += 1
                
                if indexPath.row == matchingRows {
                    let trimmed = desc.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let vc = LongTextViewController(attributedText: trimmed.convertHtml())
                    vc.title = "Setlist Notes"
                    
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            if artist.features.ratings {
                matchingRows += 1
                
                if indexPath.row == matchingRows {
                    let vc = ReviewsViewController(reviewsForSource: source, byArtist: artist)
                    
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            if artist.features.reviews {
                matchingRows += 1
                
                if indexPath.row == matchingRows {
                    let vc = ReviewsViewController(reviewsForSource: source, byArtist: artist)
                    
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        else if indexPath.section == 1 {
            let link = source.links[indexPath.row]
            
            navigationController?.present(SFSafariViewController(url: URL(string: link.url)!), animated: true, completion: nil)
        }
    }
    
    func render() {
        layout {
            return self.buildLayout()
        }
    }
}
