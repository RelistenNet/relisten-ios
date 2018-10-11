//
//  VenueMapNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/9/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import MapKit

public class VenueMapNode : ASCellNode {
    public let venue: VenueWithShowCount
    public let artist: Artist?
    var haveLoadedMapCoordinates : Bool = false
    
    public init(venue: VenueWithShowCount, forArtist artist: Artist? = nil) {
        self.venue = venue
        self.artist = artist
        
        self.venueMap = ASMapNode()
        self.venueMap.isLiveMap = true
        self.venueMap.style.preferredSize = CGSize(width: UIScreen.main.bounds.width, height: 180.0)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
        
        self.addCoordinatesToMapView()
    }
    
    public let venueMap: ASMapNode
    
    func addCoordinate(_ centerCoordinate: CLLocationCoordinate2D, animated: Bool) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate
        
        self.venueMap.annotations = [annotation]
        
        // 5km x 5km
        let options : MKMapSnapshotter.Options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        self.venueMap.options = options
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
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mapLayout: ASStackLayoutSpec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: ArrayNoNils(
                venueMap
            )
        )
        mapLayout.style.minHeight = ASDimension(unit: .points, value: 180.0)
        mapLayout.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            child: mapLayout
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
