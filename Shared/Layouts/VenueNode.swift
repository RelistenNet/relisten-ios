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
    var haveLoadedMapCoordinates : Bool = false
    
    public init(venue: VenueWithShowCount, forArtist artist: Artist? = nil, includeMap: Bool = false) {
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
        
        if includeMap == true {
            self.venueMap = ASMapNode()
            self.venueMap?.isLiveMap = true
        } else {
            self.venueMap = nil
        }
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
        
        if includeMap == true {
            self.addCoordinatesToMapView()
        }
    }
    
    func addCoordinate(_ centerCoordinate: CLLocationCoordinate2D, animated: Bool) {
        guard self.venueMap?.mapView != nil else { return }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate
        
        self.venueMap?.annotations = [annotation]
        
        // 5km x 5km
        let options : MKMapSnapshotter.Options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        self.venueMap?.options = options
    }
    
    /// https://developer.apple.com/documentation/corelocation/converting_between_coordinates_and_user_friendly_place_names
    func getCoordinate( addressString : String,
                        completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            
            completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
        }
    }
    
    func addCoordinatesToMapView() {
        if haveLoadedMapCoordinates { return }
        
        haveLoadedMapCoordinates = true
        
        if self.artist?.features.venue_coords != nil,
           let lat = venue.latitude,
           let long = venue.longitude {
            self.addCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: long), animated: false)
        }
        else {
            let address = String(format: "%@, %@", venue.name, venue.location)
            getCoordinate(addressString: address) { (coord, err) in
                guard err == nil else {
                    self.getCoordinate(addressString: self.venue.location) {(coord, err) in
                            guard err == nil else {
                                LogWarn("Error getting coordinates for \(self.venue.name), \(self.venue.location): \(err!)")
                                return
                            }
                        
                            self.addCoordinate(coord, animated: false)
                    }
                    
                    return
                }
                
                self.addCoordinate(coord, animated: false)
            }
        }
    }
    
    public let venueNameNode: ASTextNode
    public let venueLocation: ASTextNode
    public let venuePastNames: ASTextNode?
    public let showCountNode: ASTextNode
    public let venueMap: ASMapNode?
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var mapLayout: ASStackLayoutSpec? = nil
        if venueMap != nil {
            mapLayout = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 0,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: ArrayNoNils(
                    venueMap
                )
            )
            mapLayout?.style.minHeight = ASDimension(unit: .points, value: 180.0)
            mapLayout?.style.alignSelf = .stretch
        }
        
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
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                venueInfo,
                showCountNode
            )
        )
        venueAndCount.style.alignSelf = .stretch
        
        let fullVenue = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                mapLayout,
                venueAndCount
            )
        )
        fullVenue.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: fullVenue
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
