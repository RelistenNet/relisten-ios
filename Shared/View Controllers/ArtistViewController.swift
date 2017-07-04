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
        
        resourceTodayData = resourceToday.latestData?.typedContent()
        
        layout(width: tableView.bounds.size.width, synchronous: false) { self.buildLayout() }

        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 60)
        av.frame.size = av.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))

        tableView.addSubview(av)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        layout(width: size.width, synchronous: true) { self.buildLayout() }
    }
    
    func buildLayout() -> [Section<[Layout]>] {
        return [
        ]
    }
    
    // recently played by band
    // recently played by user
    // recently added
}
