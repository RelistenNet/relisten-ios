//
//  YearsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class YearsViewController: RelistenTableViewController<[Year]> {
    
    let artist: SlimArtistWithFeatures
    
    public required init(artist: SlimArtistWithFeatures) {
        self.artist = artist
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Years"
    }
    
    override var resource: Resource? { get { return api.years(byArtist: artist) } }
    
    override func render(forData: [Year]) {
        layout {
            return forData.map { YearLayout(year: $0) }.asTable()
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            navigationController?.pushViewController(YearViewController(artist: artist, year: d[indexPath.row]), animated: true)
        }
    }
}
