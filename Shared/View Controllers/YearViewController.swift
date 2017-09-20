//
//  YearViewController.swift
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

class YearViewController: RelistenTableViewController<YearWithShows> {
    let artist: SlimArtistWithFeatures
    let year: Year
    
    public required init(artist: SlimArtistWithFeatures, year: Year) {
        self.artist = artist
        self.year = year
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = year.year
    }
    
    override var resource: Resource? { get { return api.shows(inYear: year, byArtist: artist) } }
    
    var showMapping: [IndexPath: Show]? = nil
    
    override func render(forData: YearWithShows) {
        layout {
            var sections: [Section<[Layout]>] = []
            
            self.showMapping = [:]
            
            var currentSection: [Layout] = []
            
            for (idx, show) in forData.shows.enumerated() {
                if idx == 0 {
                    currentSection.append(YearShowLayout(show: show))
                    self.showMapping?[IndexPath(row: 0, section: 0)] = show
                }
                else {
                    let prevShow = forData.shows[idx - 1]
                    
                    if prevShow.tour_id != show.tour_id {
                        sections.append(LayoutsAsSingleSection(items: currentSection, title: prevShow.tour?.name))
                        
                        currentSection = []
                    }
                    
                    self.showMapping?[IndexPath(row: currentSection.count, section: sections.count)] = show
                    currentSection.append(YearShowLayout(show: show))
                    
                    if idx == forData.shows.count - 1 {
                        sections.append(LayoutsAsSingleSection(items: currentSection, title: show.tour?.name))
                    }
                }
            }
            
            return sections
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = showMapping, let show = d[indexPath] {
            navigationController?.pushViewController(SourcesViewController(artist: artist, show: show), animated: true)
        }
    }
}
