//
//  SourceDetailsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import AsyncDisplayKit
import SafariServices

public struct SourceDetailsNodeCell {
    let cell: ASCellNode
    var shouldHighlight: Bool = true
    let action: (() -> Void)?
}

public class SourceDetailsViewController : RelistenBaseAsyncTableViewController {
    enum Sections: Int, RawRepresentable {
        case venue = 0
        case credits
        case count
    }
    
    enum VenueRows: Int, RawRepresentable {
        case venueMap = 0
        case venueInfo
        case taperInfo
        case taperNotes
        case setlistNotes
        case ratings
        case reviews
        case count
    }
    
    let artist: Artist
    let show: ShowWithSources
    let source: SourceFull
    let venue: VenueWithShowCount?
    
    var venueNodes: [SourceDetailsNodeCell] = []
    let creditNodes: [UpstreamSourceNode]
    
    public required init(artist: Artist, show: ShowWithSources, source: SourceFull) {
        self.artist = artist
        self.show = show
        self.source = source
        self.venue = show.correctVenue(withFallback: source.venue)
        
        self.creditNodes = source.links.compactMap({ link -> UpstreamSourceNode? in
            if let upstream = artist.upstream_sources.first(where: { $0.upstream_source_id == link.upstream_source_id }),
                let upstreamSource = upstream.upstream_source {
                return UpstreamSourceNode(link: link, forUpstreamSource: upstreamSource)
            }
            return nil
        })
        
        super.init()
        
        if let venue = venue {
            let mapNode = VenueMapCellNode(venue: venue, forArtist: artist)
            let mapCell = SourceDetailsNodeCell(cell: mapNode, shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                s.navigationController?.pushViewController(VenueViewController(artist: s.artist, venue: venue), animated: true)
                
            }
            venueNodes.append(mapCell)
            
            let venueNode = VenueCellNode(venue: venue, forArtist: artist)
            let venueCell = SourceDetailsNodeCell(cell: venueNode, shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                s.navigationController?.pushViewController(VenueViewController(artist: s.artist, venue: venue), animated: true)
                
            }
            venueNodes.append(venueCell)
        }
        
        let taperInfoNode = TaperInfoNode(source: source, includeDetails: true, padLeft: true)
        taperInfoNode.accessoryType = .disclosureIndicator
        if taperInfoNode.hasAnyInfo {
            let taperCell = SourceDetailsNodeCell(cell: taperInfoNode, shouldHighlight: false, action: nil)
            venueNodes.append(taperCell)
        }
        
        if artist.features.taper_notes, let notes = source.taper_notes, notes.count > 0 {
            let cell = ASTextCellNode("Taper Notes", textStyle: .body)
            cell.accessoryType = .disclosureIndicator
            let taperNotesCell = SourceDetailsNodeCell(cell: cell, shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                let vc = LongTextViewController(text: notes, withFont: UIFont(name: "Courier", size: 14.0)!)
                vc.title = "Taper Notes"
                
                s.navigationController?.pushViewController(vc, animated: true)
            }
            venueNodes.append(taperNotesCell)
        }
        
        if artist.features.descriptions, let desc = source.description {
            let trimmed = desc.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).convertHtml()
            let cell = ASTextCellNode("Description / Setlist Notes", textStyle: .body)
            cell.accessoryType = .disclosureIndicator
            let setlistNotesCell = SourceDetailsNodeCell(cell: cell, shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                let vc = LongTextViewController(attributedText: trimmed)
                vc.title = "Setlist Notes"
                
                s.navigationController?.pushViewController(vc, animated: true)
            }
            venueNodes.append(setlistNotesCell)
        }
        
        if artist.features.ratings,
            let numRatings = source.num_ratings,
            numRatings > 0 {
            let ratingsCell = SourceDetailsNodeCell(cell: CompactReviewCellNode(averageRating: source.avg_rating, numRatings: source.num_ratings), shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                    let vc = ReviewsViewController(reviewsForSource: s.source, byArtist: s.artist)
                    s.navigationController?.pushViewController(vc, animated: true)
            }
            venueNodes.append(ratingsCell)
        }
        
        if artist.features.reviews, source.num_reviews > 0 {
            let cell = ASTextCellNode(source.review_count.pluralize("Review", "Reviews"), textStyle: .body)
            cell.accessoryType = .disclosureIndicator
            let ratingsCell = SourceDetailsNodeCell(cell: cell, shouldHighlight: true) { [weak self] in
                guard let s = self else { return }
                let vc = ReviewsViewController(reviewsForSource: s.source, byArtist: s.artist)
                s.navigationController?.pushViewController(vc, animated: true)
            }
            venueNodes.append(ratingsCell)
        }
        
        self.tableNode.view.separatorStyle = .singleLine
        self.tableNode.view.backgroundColor = AppColors.lightGreyBackground
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
}

// MARK: ASTableDataSource
extension SourceDetailsViewController {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .venue:
            return venueNodes.count
        case .credits:
            return creditNodes.count
        case .count:
            fatalError()
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        guard indexPath.section >= 0, indexPath.section < Sections.count.rawValue else {
            LogError("Index for section out of bounds: \(indexPath)")
            return ASCellNode()
        }
        
        switch Sections(rawValue: indexPath.section)! {
        case .venue:
            guard indexPath.row >= 0, indexPath.row < venueNodes.count else {
                LogError("Index for venue cell out of bounds: \(indexPath)")
                return ASCellNode()
            }
            
            return venueNodes[indexPath.row].cell
        case .credits:
            guard indexPath.row >= 0, indexPath.row < creditNodes.count else {
                LogError("Index for credits cell out of bounds: \(indexPath)")
                return ASCellNode()
            }
            return creditNodes[indexPath.row]
        case .count:
            fatalError()
        }
        
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .venue:
            return nil
        case .credits:
            return "Credits"
        case .count:
            fatalError()
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section >= 0, indexPath.section < Sections.count.rawValue else {
            LogError("Index for section out of bounds: \(indexPath)")
            return
        }
        
        switch Sections(rawValue: indexPath.section)! {
        case .venue:
            guard indexPath.row >= 0, indexPath.row < venueNodes.count else {
                LogError("Index for venue cell out of bounds: \(indexPath)")
                return
            }
            let venueNodeCell = venueNodes[indexPath.row]
            if let action = venueNodeCell.action {
                action()
            }
        case .credits:
            guard indexPath.row >= 0, indexPath.row < creditNodes.count else {
                LogError("Index for credits cell out of bounds: \(indexPath)")
                return
            }
            let upstreamNode = creditNodes[indexPath.row]
            if let url = URL(string: upstreamNode.link.url) {
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            }
        case .count:
            fatalError()
        }
        tableNode.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch Sections(rawValue: indexPath.section)! {
        case .venue:
            guard indexPath.row >= 0, indexPath.row < venueNodes.count else {
                LogError("Index for venue cell out of bounds: \(indexPath)")
                return false
            }
            return venueNodes[indexPath.row].shouldHighlight
        case .credits:
            return true
        default:
            return false
        }
    }
}
