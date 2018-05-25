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
        super.viewDidLoad()

        tableView.separatorStyle = .none
        
        title = artist.name
        
        resourceToday.addObserver(self)
            .addObserver(statusOverlay)
        
//        layout(width: tableView.bounds.size.width, synchronous: false) { self.buildLayout() }

        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 16)
        av.frame.size = av.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let containerView = UIView(frame: av.frame.insetBy(dx: 0, dy: -32).insetBy(dx: 0, dy: 16))
        containerView.addSubview(av)

        tableView.tableHeaderView = containerView
        
//        tableView.contentInset.top += av.frame.size.height
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resourceToday.loadFromCacheThenUpdate()
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
        return HorizontalShowCollection(makeAdapater: { (collectionView) -> ReloadableViewLayoutAdapter in
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
    
    func buildLayout() -> [Section<[Layout]>] {
        guard let today = resourceTodayData else {
            return []
        }
        
        let todayTitle = "\(today.count) Show\(today.count != 1 ? "s" : "") on " + ArtistViewController.dateFormatter.string(from: Date())
        
        return [
            LayoutsAsSingleSection(items: [todayLayout], title: todayTitle)
        ]
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
}
