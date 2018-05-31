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

public class ArtistViewController : RelistenBaseTableViewController {
    internal let statusOverlay = RelistenResourceStatusOverlay()

    public let artist: ArtistWithCounts
    
    let resourceToday: Resource
    var resourceTodayData: [Show]? = nil
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        resourceToday = RelistenApi.onThisDay(byArtist: artist)
        
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported...like at all.")
    }

    private var av: RelistenMenuView! = nil
    public override func viewDidLoad() {
        if artist.name == "Phish" {
            AppColors_SwitchToPhishOD(navigationController)
            cellDefaultBackgroundColor = UIColor.clear
        }
        else {
            AppColors_SwitchToRelisten(navigationController)
            cellDefaultBackgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        }
        
        navigationItem.largeTitleDisplayMode = .always

        super.viewDidLoad()

        tableView.separatorStyle = .none
        
        title = artist.name
        
        resourceToday.addObserver(self)
            .addObserver(statusOverlay)
        
        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 16)
        av.frame.size = av.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let containerView = UIView(frame: av.frame.insetBy(dx: 0, dy: -48).insetBy(dx: 0, dy: 16))
        containerView.addSubview(av)

        tableView.tableHeaderView = containerView
        
        setupBackgroundSlideshow()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resourceToday.loadFromCacheThenUpdate()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppear_SlideShow(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewWillDisappear_SlideShow(animated)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        layout(width: size.width, synchronous: true) { self.buildLayout() }
    }
    
    static var dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        return d
    }()
    
    lazy var todayLayout: CollectionViewLayout = {
        return HorizontalShowCollection(
            withId: "today",
            makeAdapater: { (collectionView) -> ReloadableViewLayoutAdapter in
            self.todayLayoutAdapater = CellSelectCallbackReloadableViewLayoutAdapter(reloadableView: collectionView) { indexPath in
                if let today = self.resourceTodayData, indexPath.item < today.count {
                    let item = today[indexPath.item]
                    let vc = SourcesViewController(artist: self.artist, show: item)
                    
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
                return true
            }
            return self.todayLayoutAdapater!
        }) { () -> [Section<[Layout]>] in
            guard let today = self.resourceTodayData else {
                return []
            }
            
            let todayItems = today.map({ YearShowLayout(show: $0, withRank: nil, verticalLayout: true) })
            return [LayoutsAsSingleSection(items: todayItems)]
        }
    }()
    var todayLayoutAdapater: ReloadableViewLayoutAdapter? = nil
    
    lazy var recentlyPlayedLayout: CollectionViewLayout = {
        return HorizontalShowCollection(
            withId: "recentlyPlayed",
            makeAdapater: { (collectionView) -> ReloadableViewLayoutAdapter in
            self.recentlyPlayedLayoutAdapter = CellSelectCallbackReloadableViewLayoutAdapter(reloadableView: collectionView) { indexPath in
                let recent = MyLibraryManager.shared.library.recentlyPlayedByArtist(self.artist)

                if indexPath.item < recent.count {
                    let item = recent[indexPath.item]
                    let vc = SourcesViewController(artist: self.artist, show: item.show)
                    
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
                return true
            }
            return self.recentlyPlayedLayoutAdapter!
        }) { () -> [Section<[Layout]>] in
            let recent = MyLibraryManager.shared.library.recentlyPlayedByArtist(self.artist)
            
            let recentItems = recent.map({ YearShowLayout(show: $0.show, withRank: nil, verticalLayout: true) })
            return [LayoutsAsSingleSection(items: recentItems)]
        }
    }()
    var recentlyPlayedLayoutAdapter: ReloadableViewLayoutAdapter? = nil
    
    func buildLayout() -> [Section<[Layout]>] {
        guard let today = resourceTodayData else {
            return []
        }
        
        var sections: [Section<[Layout]>] = []
        
        if today.count > 0 {
            let todayTitle = "\(today.count) Show\(today.count != 1 ? "s" : "") on " + ArtistViewController.dateFormatter.string(from: Date())

            sections.append(LayoutsAsSingleSection(items: [todayLayout], title: todayTitle))
        }
        
        if MyLibraryManager.shared.library.recentlyPlayedByArtist(self.artist).count > 0 {
            let recentTitle = "My Recently Played Shows"

            sections.append(LayoutsAsSingleSection(items: [recentlyPlayedLayout], title: recentTitle))
        }
        
        return sections
    }
    
    func render() {
        layout(layout: self.buildLayout)
    }
    
    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        resourceTodayData = resource.latestData?.typedContent()
        
        render()
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
        
        view.addSubview(fog)
        
        view.sendSubview(toBack: fog)
        view.sendSubview(toBack: slider)
        
        tableView.backgroundColor = UIColor.clear
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
