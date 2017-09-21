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

class ShowListViewController<T> : RelistenTableViewController<T> {
    let artist: SlimArtistWithFeatures
    let showsResource: Resource
    let tourSections: Bool
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource, tourSections: Bool) {
        self.artist = artist
        self.showsResource = showsResource
        self.tourSections = tourSections
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override var resource: Resource? { get { return showsResource } }
    
    var showMapping: [IndexPath: Show]? = nil

    public func layout(show: Show, atIndex: IndexPath) -> Layout {
        return YearShowLayout(show: show)
    }
    
    public func extractShows(forData: T) -> [Show] {
        fatalError("need to override this")
    }
    
    public override func render(forData: T) {
        render(shows: extractShows(forData: forData))
    }
    
    override func has(oldData: T, changed: T) -> Bool {
        let x1 = extractShows(forData: oldData)
        let x2 = extractShows(forData: changed)
        
        return x1.count != x2.count
    }
    
    public func render(shows: [Show]) {
        layout {
            if self.tourSections == false {
                let itms = shows.enumerated().map {
                    self.layout(show: $0.element, atIndex: IndexPath(row: $0.offset, section: 0))
                }
                
                return [ LayoutsAsSingleSection(items: itms, title: nil) ]
            }
            
            var sections: [Section<[Layout]>] = []
            
            self.showMapping = [:]
            
            var currentSection: [Layout] = []
            
            for (idx, show) in shows.enumerated() {
                if idx == 0 {
                    let idxP = IndexPath(row: 0, section: 0)
                    
                    currentSection.append(self.layout(show: show, atIndex: idxP))
                    self.showMapping?[idxP] = show
                }
                else {
                    let prevShow = shows[idx - 1]
                    
                    if prevShow.tour_id != show.tour_id {
                        sections.append(LayoutsAsSingleSection(items: currentSection, title: prevShow.tour?.name))
                        
                        currentSection = []
                    }
                    
                    let idxP = IndexPath(row: currentSection.count, section: sections.count)
                    self.showMapping?[idxP] = show
                    currentSection.append(self.layout(show: show, atIndex: idxP))
                    
                    if idx == shows.count - 1 {
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

        var show: Show? = nil
        if tourSections, let d = showMapping, let s = d[indexPath] {
            show = s
        }
        else if !tourSections, let d = latestData {
            show = self.extractShows(forData: d)[indexPath.row]
        }

        if let s = show {
            navigationController?.pushViewController(SourcesViewController(artist: artist, show: s), animated: true)
        }
    }
}

class YearViewController: ShowListViewController<YearWithShows> {
    let year: Year
    
    public required init(artist: SlimArtistWithFeatures, year: Year) {
        self.year = year
        
        super.init(artist: artist, showsResource: RelistenApi.shows(inYear: year, byArtist: artist), tourSections: true)
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override func extractShows(forData: YearWithShows) -> [Show] {
        return forData.shows
    }
}
