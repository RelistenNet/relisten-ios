//
//  SourcesViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

class SourcesViewController: RelistenAsyncTableController<ShowWithSources> {
    
    let artist: ArtistWithCounts
    let show: Show?
    let isRandom: Bool
    
    var sources: [SourceFull] = []
    var sourceToPresent : SourceFull?
    var canSkipIfSingleSource : Bool
    
    public required init(artist: ArtistWithCounts, show: Show) {
        self.artist = artist
        self.show = show
        self.isRandom = false
        self.canSkipIfSingleSource = false
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    public required init(artist: ArtistWithCounts) {
        self.show = nil
        self.artist = artist
        self.isRandom = true
        self.canSkipIfSingleSource = false
        
        super.init(useCache: false, refreshOnAppear: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func presentIfNecessary(navigationController : UINavigationController?, forSource source: SourceFull? = nil) {
        self.load()
        var controllerToPresent : UIViewController = self
        sourceToPresent = source
        if let show = latestData {
            if self.sources.count == 1 {
                controllerToPresent = SourceViewController(artist: artist, show: show, source: sources[0])
            } else if let source = source {
                controllerToPresent = SourceViewController(artist: artist, show: show, source: source)
            }
        }
        navigationController?.pushViewController(controllerToPresent, animated: true)
        canSkipIfSingleSource = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !self.canSkipIfSingleSource {
            updateTitle(forShow: show)
        }
    }
    
    func updateTitle(forShow: Show?) {
        if let s = forShow {
            title = "\(s.display_date) Sources"
        }
    }
    
    override var resource: Resource? {
        get {
            return self.show == nil ? api.randomShow(byArtist: artist) : api.showWithSources(forShow: show!, byArtist: artist)
        }
    }
    
    override func dataChanged(_ data: ShowWithSources) {
        var shouldReloadTitle = true
        
        sources = data.sources
        if canSkipIfSingleSource {
            var controllerToPresent : SourceViewController?
            if sources.count == 1 {
                controllerToPresent = SourceViewController(artist: artist, show: data, source: sources[0])
            } else if let source = sourceToPresent {
                controllerToPresent = SourceViewController(artist: artist, show: data, source: source)
            }
            
            if let controllerToPresent = controllerToPresent {
                if var viewControllers = navigationController?.viewControllers {
                    if viewControllers.last == self {
                        viewControllers.removeLast()
                    }
                    viewControllers.append(controllerToPresent)
                    navigationController?.setViewControllers(viewControllers, animated: false)
                    shouldReloadTitle = false
                }
            } else {
                canSkipIfSingleSource = false
                tableNode.reloadData()
            }
        }
        
        if shouldReloadTitle {
            updateTitle(forShow: data)
        }
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        if canSkipIfSingleSource {
            return 0
        }
        return sources.count > 0 ? 1 : 0
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if canSkipIfSingleSource {
            return 0
        }
        return sources.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let show = latestData else { return { ASCellNode() } }
        
        let source = sources[indexPath.row]
        let artist = self.artist
        
        return { SourceDetailsNode(source: source, inShow: show, artist: artist, atIndex: indexPath.row, isDetails: false) }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        guard let show = latestData else { return }

        let vc = SourceViewController(artist: artist, show: show, source: sources[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
