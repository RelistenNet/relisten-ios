//
//  VenuesViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class VenuesViewController: RelistenTableViewController<[VenueWithShowCount]> {
    
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Venues"
    }
    
    override var resource: Resource? { get { return api.venues(forArtist: artist) } }
    
    var groups: [Grouping<String, VenueWithShowCount>]? = nil
    
    override func render(forData: [VenueWithShowCount]) {
        let digitSet = CharacterSet.decimalDigits
        
        groups = sinq(forData)
            .groupBy({
                let n = $0.sortName
                var s = n[..<n.index(n.startIndex, offsetBy: 1)].uppercased()
                
                for ch in s.unicodeScalars {
                    if digitSet.contains(ch) {
                        s = "#"
                        break
                    }
                }
                
                return s
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })

        layout {
            guard let g = self.groups else {
                return [Section(header: nil, items: [], footer: nil)]
            }
            
            return g.map {
                LayoutsAsSingleSection(items: $0.values.map({ (v) in
                    return VenueLayout(venue: v)
                }), title: $0.key as String?)
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let g = groups {
            return g.map({ $0.key })
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let g = groups {
            let v = g[indexPath.section].values.elementAt(indexPath.row)
            navigationController?.pushViewController(VenueViewController(artist: artist, venue: v), animated: true)
        }
    }
}
