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
    public let artist: Artist
    
    public required init(artist: Artist) {
        self.artist = artist
        
        resourceToday = RelistenApi.onThisDay(byArtist: artist)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported...like at all.")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = artist.name
        
        resourceTodayData = resourceToday.latestData?.typedContent()
        
        layout(width: tableView.bounds.size.width, synchronous: false) { self.buildLayout() }
    }
    
    private var av: RelistenMenuView! = nil
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        av = RelistenMenuView(artist: artist)
        av.frame.origin = CGPoint(x: 0, y: 60)
        av.frame.size = av.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        tableView.addSubview(av)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        layout(width: size.width, synchronous: true) { self.buildLayout() }
    }
    
    func buildLayout() -> [Section<[Layout]>] {
        return [
        ]
    }
    
    let resourceToday: Resource
    var resourceTodayData: [Show]? = nil
    
    // recently played by band
    // recently played by user
    // recently added
}
