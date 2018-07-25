//
//  ArtistViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import LayoutKit
import KASlideShow
import AsyncDisplayKit

extension Calendar {
    static func currentDayOfMonth() -> Int {
        return Calendar.autoupdatingCurrent.component(.day, from: Date())
    }
}

public class ArtistViewController : RelistenBaseAsyncTableViewController {
    enum Sections: Int, RawRepresentable {
        case today = 0
        case recentlyPlayed
        case count
    }

    internal let statusOverlay = RelistenResourceStatusOverlay()

    public let artist: ArtistWithCounts
    
    let resourceToday: Resource
    var resourceTodayData: [Show]? = nil
    private var lastTodayShowsUpdateDay : Int
    
    public var recentlyPlayedTracks: [Track] = []
    public let recentShowsNode: HorizontalShowCollectionCellNode
    public let todayShowsNode: HorizontalShowCollectionCellNode

    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        recentShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        todayShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        
        recentShowsNode.cellTransparency = 0.9
        todayShowsNode.cellTransparency = 0.9

        resourceToday = RelistenApi.onThisDay(byArtist: artist)
        
        lastTodayShowsUpdateDay = Calendar.currentDayOfMonth()
        
        super.init()
        
        recentShowsNode.collectionNode.delegate = self
        todayShowsNode.collectionNode.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported...like at all.")
    }

    private var av: RelistenMenuView! = nil
    public override func viewDidLoad() {
        if artist.name == "Phish" {
            AppColors_SwitchToPhishOD(navigationController)
//            cellDefaultBackgroundColor = UIColor.clear
        }
        else {
            AppColors_SwitchToRelisten(navigationController)
//            cellDefaultBackgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        }
        
        navigationItem.largeTitleDisplayMode = .always

        super.viewDidLoad()

        tableNode.view.separatorStyle = .none
        
        title = artist.name
        
        resourceToday.addObserver(self)
            .addObserver(statusOverlay)
        resourceToday.loadFromCacheThenUpdate()
        
        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 16)
        av.frame.size = av.sizeThatFits(CGSize(width: tableNode.view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let containerView = UIView(frame: av.frame.insetBy(dx: 0, dy: -48).insetBy(dx: 0, dy: 16))
        containerView.addSubview(av)

        tableNode.view.tableHeaderView = containerView
        
        setupBackgroundSlideshow()
        
        MyLibraryManager.shared.observeRecentlyPlayedTracks.observe({ [weak self] tracks, _ in
            guard let s = self else { return }
            s.reloadRecentShows(tracks: tracks)
        }).add(to: &disposal)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // No need to reload shows on this day if the day hasn't changed
        if Calendar.currentDayOfMonth() != lastTodayShowsUpdateDay {
            resourceToday.loadFromCacheThenUpdate()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppear_SlideShow(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewWillDisappear_SlideShow(animated)
    }
    
    private func reloadRecentShows(tracks: [Track]) {
        let filteredTracks = tracks.filter { (track) -> Bool in
            return track.showInfo.artist == artist
        }
        if !(filteredTracks == recentlyPlayedTracks) {
            DispatchQueue.main.async {
                self.recentlyPlayedTracks = filteredTracks
                self.recentShowsNode.shows = self.recentlyPlayedTracks.map({ ($0.showInfo.show, $0.showInfo.artist) })
                self.tableNode.reloadSections([ Sections.recentlyPlayed.rawValue ], with: .automatic)
            }
        }
    }
    
    private func reloadShowsOnThisDate(todaysShows: [Show]) {
        if !(todaysShows == resourceTodayData) {
            var shows : [(show: Show, artist: ArtistWithCounts?)] = []
            todaysShows.forEach { (show) in
                shows.append((show: show, artist: artist))
            }
            
            DispatchQueue.main.async {
                self.resourceTodayData = todaysShows
                self.todayShowsNode.shows = todaysShows.map({ ($0, nil) })
                self.tableNode.reloadSections([ Sections.today.rawValue ], with: .automatic)
            }
        }
    }
    
    static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        return d
    }()
    
    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        if let todaysShows : [Show] = resource.latestData?.typedContent() {
            reloadShowsOnThisDate(todaysShows: todaysShows)
        }
    }
    
    // recently played by band
    // recently played by user
    // recently added
    
    var shuffledImageNames: [NSString] = []
    var slider: KASlideShow! = nil
}

extension ArtistViewController : KASlideShowDataSource {
    public func slideShow(_ slideShow: KASlideShow!, objectAt index: UInt) -> NSObject! {
        return shuffledImageNames[Int(index)]
    }
    
    public func slideShowImagesNumber(_ slideShow: KASlideShow!) -> UInt {
        return artist.name == "Phish" ? 36 : 0
    }
    
    public func setupBackgroundSlideshow() {
        guard artist.name == "Phish" else {
            return
        }
        
        for i in 1...36 {
            shuffledImageNames.append(NSString(string: "phishod_bg_" + (i < 10 ? "0" : "") + String(i)))
        }
        
        shuffledImageNames.shuffle()
        
        slider = KASlideShow(frame: view.bounds)
        
        slider.datasource = self
        slider.imagesContentMode = .scaleAspectFill
        slider.delay = 7.5
        slider.transitionDuration = 1.0
        slider.transitionType = .fade
        
        slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(slider)
        
        let fog = UIView(frame: view.bounds)
        fog.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fog.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        
        slider.addSubview(fog)
        
        view.sendSubview(toBack: fog)
        view.sendSubview(toBack: slider)
        
        tableNode.backgroundColor = UIColor.clear
    }
    
    public override func viewWillLayoutSubviews() {
        if let slider = slider {
            view.sendSubview(toBack: slider)
        }
    }
    
    public func viewWillDisappear_SlideShow(_ animated: Bool) {
        if let s = slider {
            s.stop()
        }
    }
    
    public func viewDidAppear_SlideShow(_ animated: Bool) {
        if let s = slider {
            s.start()
        }
    }
}

extension ArtistViewController {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .today:
            return (resourceTodayData?.count ?? 0) > 0 ? 1 : 0
        case .recentlyPlayed:
            return recentlyPlayedTracks.count > 0 ? 1 : 0
        case .count:
            fatalError()
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        switch Sections(rawValue: indexPath.section)! {
        case .today:
            let n = todayShowsNode
            return { n }
        case .recentlyPlayed:
            let n = recentShowsNode
            return { n }
        case .count:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .today:
            if let t = resourceTodayData {
                return "\(t.count) Show\(t.count != 1 ? "s" : "") on " + ArtistViewController.dateFormatter.string(from: Date())
            }
            else {
                return nil
            }
        case .recentlyPlayed:
            return recentlyPlayedTracks.count > 0 ? "My Recently Played Shows" : nil
        default:
            return nil
        }
    }
}

extension ArtistViewController : ASCollectionDelegate {
    public func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        if collectionNode === todayShowsNode.collectionNode, let today = resourceTodayData {
            let item = today[indexPath.row]
            let vc = SourcesViewController(artist: self.artist, show: item)
            vc.presentIfNecessary(navigationController: navigationController)
        }
        else if collectionNode === recentShowsNode.collectionNode {
            let item = recentlyPlayedTracks[indexPath.row]
            let vc = SourcesViewController(artist: self.artist, show: item.showInfo.show)
            vc.presentIfNecessary(navigationController: navigationController)
        }
    }
}
