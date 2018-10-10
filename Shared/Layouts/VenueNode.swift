//
//  VenueNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/5/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import MapKit

public class VenueNode : ASCellNode {
    public let venue: VenueWithShowCount
    public let artist: Artist?
    
    public init(venue: VenueWithShowCount, forArtist artist: Artist? = nil) {
        self.venue = venue
        self.artist = artist
        
        self.venueNameNode = ASTextNode(venue.name, textStyle: .headline)
        self.venueLocation = ASTextNode(venue.location, textStyle: .subheadline)
        if let pastNames = venue.past_names {
            self.venuePastNames = ASTextNode(pastNames, textStyle: .subheadline)
        } else {
            self.venuePastNames = nil
        }
        self.showCountNode = ASTextNode(venue.shows_at_venue.pluralize("show", "shows"), textStyle: .caption1)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
    }
        
    public let venueNameNode: ASTextNode
    public let venueLocation: ASTextNode
    public let venuePastNames: ASTextNode?
    public let showCountNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let venueInfo = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                venueNameNode,
                venuePastNames,
                venueLocation
            )
        )
        venueInfo.style.alignSelf = .stretch
        
        let venueAndCount = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: ArrayNoNils(
                venueInfo,
                showCountNode
            )
        )
        venueAndCount.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: venueAndCount
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
