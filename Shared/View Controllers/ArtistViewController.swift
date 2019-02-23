//
//  ArtistViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import KASlideShow
import AsyncDisplayKit
import RealmSwift

extension Calendar {
    static func currentDayOfMonth() -> Int {
        return Calendar.autoupdatingCurrent.component(.day, from: Date())
    }
}

public class ArtistViewController : RelistenBaseTableViewController, ASCollectionDelegate, UIViewControllerRestoration {
    enum Sections: Int, RawRepresentable {
        case today = 0
        case recentlyPlayed
        case recentlyPerformed
        case recentlyUpdated
        case favorited
        case offline
        case count
    }

    internal let statusOverlay = RelistenResourceStatusOverlay()

    public let artist: Artist
    
    let resourceToday: Resource
    let resourceRecentlyPerformed: Resource
    let resourceRecentlyUpdated: Resource
    
    private var lastTodayShowsUpdateDay : Int
    
    public var recentlyPlayedTracks: Results<RecentlyPlayedTrack>?
    public var offlineSources: [CompleteShowInformation] = []
    public var favoritedSources: [CompleteShowInformation] = []
    public var todayShows: [ShowWithArtist] = []
    public var recentlyPerformedShows: [ShowWithArtist] = []
    public var recentlyUpdatedShows: [ShowWithArtist] = []

    public let recentShowsNode: HorizontalShowCollectionCellNode
    public let todayShowsNode: HorizontalShowCollectionCellNode
    public let recentlyPerformedNode: HorizontalShowCollectionCellNode
    public let recentlyUpdatedNode: HorizontalShowCollectionCellNode
    public let favoritedNode: HorizontalShowCollectionCellNode
    public let offlineNode: HorizontalShowCollectionCellNode
    
    lazy var settingsViewController : SettingsViewController = {
        return SettingsViewController()
    }()

    public required init(artist: Artist) {
        self.artist = artist
        
        recentShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        todayShowsNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        recentlyPerformedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        recentlyUpdatedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        favoritedNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        offlineNode = HorizontalShowCollectionCellNode(forShows: [], delegate: nil)
        
        if artist.name == "Phish" {
            let cellTransparency : CGFloat = 0.9
            recentShowsNode.cellTransparency = cellTransparency
            todayShowsNode.cellTransparency = cellTransparency
            recentlyPerformedNode.cellTransparency = cellTransparency
            recentlyUpdatedNode.cellTransparency = cellTransparency
            favoritedNode.cellTransparency = cellTransparency
            offlineNode.cellTransparency = cellTransparency
        }
        
        resourceToday = RelistenApi.onThisDay(byArtist: artist)
        resourceRecentlyPerformed = RelistenApi.recentlyPerformed(byArtist: artist)
        resourceRecentlyUpdated = RelistenApi.recentlyUpdated(byArtist: artist)

        lastTodayShowsUpdateDay = Calendar.currentDayOfMonth()
        
        super.init()
        
        self.restorationIdentifier = "net.relisten.ArtistViewController.\(artist.slug)"
        self.restorationClass = ArtistViewController.self
        
        recentShowsNode.collectionNode.delegate = self
        todayShowsNode.collectionNode.delegate = self
        recentlyPerformedNode.collectionNode.delegate = self
        recentlyUpdatedNode.collectionNode.delegate = self
        favoritedNode.collectionNode.delegate = self
        offlineNode.collectionNode.delegate = self
        
        if RelistenApp.sharedApp.isPhishOD {
            let settingsItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(presentSettings(_:)))
            self.navigationItem.rightBarButtonItem = settingsItem
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported...like at all.")
    }
    
    @objc func presentSettings(_ sender: UINavigationBar?) {
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private var av: RelistenMenuView! = nil
    public override func viewDidLoad() {
        if artist.name == "Phish" {
            AppColors_SwitchToPhishOD()
        }
        else {
            AppColors_SwitchToRelisten()
        }
        
        navigationItem.largeTitleDisplayMode = .always

        super.viewDidLoad()

        tableNode.view.separatorStyle = .none
        
        if RelistenApp.sharedApp.isPhishOD {
            title = RelistenApp.appName
        } else {
            title = artist.name
        }
        
        for res in [resourceToday, resourceRecentlyPerformed, resourceRecentlyUpdated] {
            res.addObserver(self)
            res.addObserver(statusOverlay)
            res.loadFromCacheThenUpdate()
        }
        
        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 16)
        av.frame.size = av.sizeThatFits(CGSize(width: tableNode.view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let containerView = UIView(frame: av.frame.insetBy(dx: 0, dy: -48).insetBy(dx: 0, dy: 16))
        containerView.addSubview(av)

        tableNode.view.tableHeaderView = containerView
        
        setupBackgroundSlideshow()
        
        MyLibrary.shared.recent.shows(byArtist: artist).observeWithValue { [weak self] shows, _ in
            guard let s = self else { return }
            
            DispatchQueue.main.async {
                s.recentlyPlayedTracks = shows
                if let showInfos = s.recentlyPlayedTracks?.asTracks().map({ (show: $0.showInfo.show, artist: nil, source: $0.showInfo.source) }) as [(show: Show, artist: Artist?, source: Source?)]? {
                    s.recentShowsNode.shows = showInfos
                    s.tableNode.reloadSections([ Sections.recentlyPlayed.rawValue ], with: .automatic)
                }
            }
        }.dispose(to: &disposal)
        
        MyLibrary.shared.offline.sources(byArtist: artist).observeWithValue { [weak self] sources, _ in
            guard let s = self else { return }
            
            DispatchQueue.main.async {
                s.offlineSources = sources.asCompleteShows()
                s.offlineNode.shows = s.offlineSources.map { (show: $0.show, artist: nil, source: $0.source) }

                s.tableNode.reloadSections([ Sections.offline.rawValue ], with: .automatic)
            }
        }.dispose(to: &disposal)
        
        MyLibrary.shared.favorites.sources(byArtist: artist).observeWithValue { [weak self] sources, _ in
            guard let s = self else { return }
            
            DispatchQueue.main.async {
                s.favoritedSources = sources.asCompleteShows()
                s.favoritedNode.shows = s.favoritedSources.map { (show: $0.show, artist: nil, source: $0.source) }

                s.tableNode.reloadSections([ Sections.favorited.rawValue ], with: .automatic)
            }
        }.dispose(to: &disposal)
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
    
    static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        return d
    }()
    
    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        switch event {
        case .newData(_):
            break
        default:
            return
        }
        
        DispatchQueue.main.async {
            if resource == self.resourceToday, let shows: [ShowWithArtist] = self.resourceToday.typedContent(ifNone: []) {
                self.todayShows = shows
                self.todayShowsNode.shows = shows.map { (show: $0, artist: nil, source: nil) }
                self.tableNode.reloadSections([ Sections.today.rawValue ], with: .automatic)
            }
            else if resource == self.resourceRecentlyPerformed, let shows: [ShowWithArtist] = self.resourceRecentlyPerformed.typedContent(ifNone: []) {
                self.recentlyPerformedShows = shows
                self.recentlyPerformedNode.shows = shows.map { (show: $0, artist: nil, source: nil) }
                self.tableNode.reloadSections([ Sections.recentlyPerformed.rawValue ], with: .automatic)
            }
            else if resource == self.resourceRecentlyUpdated, let shows: [ShowWithArtist] = self.resourceRecentlyUpdated.typedContent(ifNone: []) {
                self.recentlyUpdatedShows = shows
                self.recentlyUpdatedNode.shows = shows.map { (show: $0, artist: nil, source: nil) }
                self.tableNode.reloadSections([ Sections.recentlyUpdated.rawValue ], with: .automatic)
            }
        }
    }
    
    // recently played by band
    // recently played by user
    // recently added
    
    var shuffledImageNames: [NSString] = []
    var slider: KASlideShow! = nil
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .today:
            return todayShows.count > 0 ? 1 : 0
        case .recentlyUpdated:
            return recentlyUpdatedShows.count > 0 ? 1 : 0
        case .recentlyPerformed:
            return recentlyPerformedShows.count > 0 ? 1 : 0
        case .favorited:
            return favoritedSources.count > 0 ? 1 : 0
        case .offline:
            return offlineSources.count > 0 ? 1 : 0
        case .recentlyPlayed:
            if let recentlyPlayedTracks = recentlyPlayedTracks {
                return recentlyPlayedTracks.count > 0 ? 1 : 0
            } else {
                return 0
            }
        case .count:
            fatalError()
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        var n: ASCellNode
        
        switch Sections(rawValue: indexPath.section)! {
        case .today:
            n = todayShowsNode
        case .recentlyPlayed:
            n = recentShowsNode
        case .recentlyPerformed:
            n = recentlyPerformedNode
        case .recentlyUpdated:
            n = recentlyUpdatedNode
        case .favorited:
            n = favoritedNode
        case .offline:
            n = offlineNode

        case .count:
            fatalError()
        }
        
        return { n }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .today:
            if todayShows.count > 0 {
                return "\(todayShows.count) Show\(todayShows.count != 1 ? "s" : "") on " + ArtistViewController.dateFormatter.string(from: Date())
            }
            else {
                return nil
            }
        case .recentlyPlayed:
            if let recentlyPlayedTracks = recentlyPlayedTracks {
                return recentlyPlayedTracks.count > 0 ? "My Recently Played" : nil
            } else {
                return nil
            }
        case .recentlyUpdated:
            return recentlyUpdatedShows.count > 0 ? "Recently Updated" : nil
        case .recentlyPerformed:
            return recentlyPerformedShows.count > 0 ? "Recently Performed" : nil
        case .favorited:
            return favoritedSources.count > 0 ? "My Favorites" : nil
        case .offline:
            return offlineSources.count > 0 ? "Available Offline" : nil

        case .count:
            fatalError()
        }
    }
    
    //MARK: ASCollectionDelegate
    override public func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        var show: Show!
        var source: SourceFull? = nil
        
        if collectionNode === todayShowsNode.collectionNode {
            show = todayShows[indexPath.row]
        }
        else if collectionNode === recentShowsNode.collectionNode {
            if let s = recentlyPlayedTracks?[indexPath.row].track?.showInfo {
                show = s.show
                source = s.source
            }
        }
        else if collectionNode == recentlyPerformedNode.collectionNode {
            show = recentlyPerformedShows[indexPath.row]
        }
        else if collectionNode == favoritedNode.collectionNode {
            let s = favoritedSources[indexPath.row]
            
            show = s.show
            source = s.source
        }
        else if collectionNode == offlineNode.collectionNode {
            let s = offlineSources[indexPath.row]
            
            show = s.show
            source = s.source
        }
        else if collectionNode == recentlyUpdatedNode.collectionNode {
            show = recentlyUpdatedShows[indexPath.row]
        }

        let vc = SourcesViewController(artist: self.artist, show: show)
        
        if let src = source {
            vc.presentIfNecessary(navigationController: navigationController, forSource: src)
        }
        else {
            vc.presentIfNecessary(navigationController: navigationController)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: CodingKeys.artist.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let vc = ArtistViewController(artist: encodedArtist)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        // Encode the artist object so we can re-create an ArtistViewController after state restoration
        super.encodeRestorableState(with: coder)
        
        do {
            let artistData = try JSONEncoder().encode(self.artist)
            coder.encode(artistData, forKey: CodingKeys.artist.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

// MARK: Phish Slideshow

extension ArtistViewController : KASlideShowDataSource {
    public func slideShow(_ slideShow: KASlideShow!, objectAt index: UInt) -> NSObject! {
        return shuffledImageNames[Int(index)]
    }
    
    public func slideShowImagesNumber(_ slideShow: KASlideShow!) -> UInt {
        return artist.name == "Phish" ? 36 : 0
    }
    
    public func setupBackgroundSlideshow() {
        guard artist.name == "Phish - disabled" else {
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
        
        tableNode.view.backgroundView = slider
//        
        let fog = UIView(frame: view.bounds)
        fog.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fog.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        
        slider.addSubview(fog)
        
        tableNode.backgroundColor = UIColor.clear
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
