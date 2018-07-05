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
import AsyncDisplayKit
import SINQ

class ShowListViewController<T> : RelistenAsyncTableController<T> {
    internal let artist: ArtistWithCounts
    internal let showsResource: Resource?
    internal let tourSections: Bool
    
    internal var showsByTour: [(tourName: String?, shows: [Show])] = []
    
    internal var shows: [Show] = []
    
    public required init(artist: ArtistWithCounts, showsResource: Resource?, tourSections: Bool) {
        self.artist = artist
        self.showsResource = showsResource
        self.tourSections = artist.features.tours && tourSections
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /*
        trackFinishedHandler = RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(target: self, handler: ShowListViewController<T>.relayoutIfContainsTrack)
        tracksDeletedHandler = RelistenDownloadManager.shared.eventTracksDeleted.addHandler(target: self, handler: ShowListViewController<T>.relayoutIfContainsTracks)
         */
    }
    
    func relayoutIfContainsTrack(_ track: Track) {
        if let d = latestData {
            let shows = extractShows(forData: d)
            
            if sinq(shows).any({ $0.id == track.showInfo.show.id }) {
//                render(shows: shows)
            }
        }
    }
    
    func relayoutIfContainsTracks(_ tracks: [Track]) {
        if let d = latestData {
            let shows = extractShows(forData: d)
            
            let trackShowsId = tracks.map({ $0.showInfo.show.id })
            
            if sinq(shows).any({ trackShowsId.contains($0.id) }) {
//                render(shows: shows)
            }
        }
    }
    
    override var resource: Resource? { get { return showsResource } }
    
    var showMapping: [IndexPath: Show]? = nil

    public func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { YearShowCellNode(show: show) }
    }
    
    public func extractShows(forData: T) -> [Show] {
        fatalError("need to override this")
    }
    
    override func has(oldData: T, changed: T) -> Bool {
        let x1 = extractShows(forData: oldData)
        let x2 = extractShows(forData: changed)
        
        return x1.count != x2.count
    }
    
    public override func render() {
        if let d = latestData {
            shows = extractShows(forData: d)
            
            if tourSections {
                buildTourSections()
            }
        }
        
        super.render()
    }
    
    func buildTourSections() {
        var sections: [[Show]] = []
        
        showMapping = [:]
        showsByTour = []
        
        var currentSection: [Show] = []
        
        for (idx, show) in shows.enumerated() {
            if idx == 0 {
                let idxP = IndexPath(row: 0, section: 0)
                
                currentSection.append(show)
                showMapping?[idxP] = show
            }
            else {
                let prevShow = shows[idx - 1]
                
                if prevShow.tour_id != show.tour_id {
                    showsByTour.append((prevShow.tour?.name, currentSection))
                    sections.append(currentSection)
                    
                    currentSection = []
                }
                
                let idxP = IndexPath(row: currentSection.count, section: sections.count)
                showMapping?[idxP] = show
                currentSection.append(show)
            }
            
            if idx == shows.count - 1 {
                showsByTour.append((show.tour?.name, currentSection))
            }
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
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
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return tourSections ? showsByTour.count : 1
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return tourSections ? showsByTour[section].shows.count : shows.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let show = tourSections ? showsByTour[indexPath.section].shows[indexPath.row] : shows[indexPath.row]
        
        return self.layout(show: show, atIndex: indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tourSections ? showsByTour[section].tourName : nil
    }
}

class YearViewController: ShowListViewController<YearWithShows> {
    let year: Year
    
    public required init(artist: ArtistWithCounts, year: Year) {
        self.year = year
        
        super.init(artist: artist, showsResource: RelistenApi.shows(inYear: year, byArtist: artist), tourSections: true)
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override func extractShows(forData: YearWithShows) -> [Show] {
        return forData.shows
    }
    
    override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return super.numberOfSections(in: tableNode)
    }
    
    override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return super.tableNode(tableNode, numberOfRowsInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        return super.tableNode(tableNode, didSelectRowAt: indexPath)
    }
}
