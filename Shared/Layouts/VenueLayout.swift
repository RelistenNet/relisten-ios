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
import MapKit
import CoreLocation

public class VenueLayout : InsetLayout<UIView> {
    public init(venue: VenueWithShowCount, useViewLanguage: Bool = false) {
        let venueName = LabelLayout(
            text: venue.name,
            font: UIFont.preferredFont(forTextStyle: .headline),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "venueName"
        )
        
        let venuePastNames = LabelLayout(
            text: venue.past_names ?? "",
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
        
        var sb = [venueName]
        
        if(venue.past_names != nil) {
            sb.append(venuePastNames)
        }
        
        sb.append(venueLocation)
        
        var subs: [Layout] = [
            StackLayout(
                axis: .vertical,
                sublayouts: sb
            )
        ]
        
        var showText = venue.shows_at_venue.pluralize("show", "shows")
        if useViewLanguage {
            showText = "View \(showText) ›"
        }
        
        let showsLabel = LabelLayout(
            text: showText,
            font: UIFont.preferredFont(forTextStyle: .caption1),
            alignment: .centerTrailing,
            flexibility: .inflexible,
            viewReuseId: "venueShowCount"
        )
        
        subs.append(showsLabel)
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 12, right: 16 + 8 + 8 + 16),
            viewReuseId: "venueLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 8,
                sublayouts: subs
            )
        )
    }
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

public class VenueLayoutWithMap : InsetLayout<UIView> {
    public init(venue: VenueWithShowCount, forArtist: Artist) {
        var layouts: [Layout] = []
        
        let mapLayout = SizeLayout<MKMapView>(
            minHeight: 180,
            alignment: .fill,
            flexibility: .flexible,
            viewReuseId: "venueMap",
            config: { (mapView) in
                func addCoordinate(_ centerCoordinate: CLLocationCoordinate2D, animated: Bool) {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = centerCoordinate
                    
                    mapView.addAnnotation(annotation)
                    
                    // 5km x 5km
                    let viewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, 5000, 5000)
                    mapView.setRegion(viewRegion, animated: animated)
                }
                
                if forArtist.features.venue_coords, let lat = venue.latitude, let long = venue.longitude {
                    addCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: long), animated: false)
                }
                else {
                    let address = String(format: "%@, %@", venue.name, venue.location)
                    getCoordinate(
                        addressString: address,
                        completionHandler: { (coord, err) in
                            guard err == nil else {
                                getCoordinate(
                                    addressString: venue.location,
                                    completionHandler: { (coord, err) in
                                        guard err == nil else {
                                            LogWarn("Error getting coordinates for address: \(err!)")
                                            return
                                        }
                                        
                                        addCoordinate(coord, animated: false)
                                    }
                                )
                                
                                return
                            }
                            
                            addCoordinate(coord, animated: false)
                        }
                    )
                }
            }
        )
        
        layouts.append(mapLayout)
        layouts.append(VenueLayout(venue: venue, useViewLanguage: true))
        
        super.init(
            insets: EdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            viewReuseId: "venueLayout",
            sublayout: StackLayout(
                axis: .vertical,
                spacing: 8,
                sublayouts: layouts
            )
        )
    }
}
