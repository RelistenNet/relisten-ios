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

public class SourcesViewController: RelistenTableViewController<ShowWithSources>, UIViewControllerRestoration {
    
    let artist: Artist
    let show: Show?
    let isRandom: Bool
    
    private var _sources : [SourceFull] = []
    var sources: [SourceFull] {
        get { return _sources }
        set {
            _sources = sortSources(newValue)
        }
    }
    
    var sourceToPresent : SourceFull?
    var canSkipIfSingleSource : Bool
    
    public required init(artist: Artist, show: Show) {
        self.artist = artist
        self.show = show
        self.isRandom = false
        self.canSkipIfSingleSource = false
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.restorationIdentifier = "net.relisten.SourcesViewController.\(artist.slug).\(show.display_date)"
        self.restorationClass = type(of: self)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    public required init(artist: Artist) {
        self.show = nil
        self.artist = artist
        self.isRandom = true
        self.canSkipIfSingleSource = false
        
        super.init(useCache: false, refreshOnAppear: false)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func sortSources(_ sources : [SourceFull]) -> [SourceFull] {
        // The order from the server is fine, but the two most recently updated sources updated within the last three months should be displayed near the top
        var retval : [SourceFull] = sources
        if sources.count > 1 {
            let sourcesSortedByUpdate = sources.sorted(by: { return $0.updated_at > $1.updated_at })
            var recentSources : [SourceFull] = []
            if -(sourcesSortedByUpdate[0].updated_at.timeIntervalSinceNow) < (60*60*24*30*3) { // Approximately three months
                recentSources.append(sourcesSortedByUpdate[0])
            }
            if -(sourcesSortedByUpdate[1].updated_at.timeIntervalSinceNow) < (60*60*24*30*3) { // Approximately three months
                recentSources.append(sourcesSortedByUpdate[1])
            }
            if recentSources.count > 0 {
                var topSourceArray : [SourceFull] = []
                let topSource = retval.remove(at: 0)
                var topSourceIsRecent = false
                for i in 0..<recentSources.count {
                    if recentSources[i] === topSource {
                        topSourceIsRecent = true
                        break
                    }
                }
                if !topSourceIsRecent {
                    topSourceArray.append(topSource)
                }
                
                retval = retval.filter({ (curSource) -> Bool in
                    for i in 0..<recentSources.count {
                        if curSource === recentSources[i] {
                            return false
                        }
                    }
                    return true
                })
                
                retval = topSourceArray + Array(sourcesSortedByUpdate[0..<2]) + retval
            }
        }
        return retval
    }
    
    public func presentIfNecessary(navigationController : UINavigationController?, forSource source: SourceFull? = nil) {
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
    
    public override func viewDidLoad() {
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
    
    public override var resource: Resource? {
        get {
            return self.show == nil ? api.randomShow(byArtist: artist) : api.showWithSources(forShow: show!, byArtist: artist)
        }
    }
    
    public override func dataChanged(_ data: ShowWithSources) {
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
        
        if canSkipIfSingleSource {
            super.dataChanged(data)
        }
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        if canSkipIfSingleSource {
            return 0
        }
        return sources.count > 0 ? 1 : 0
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if canSkipIfSingleSource {
            return 0
        }
        return sources.count
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let show = latestData else { return { ASCellNode() } }
        
        let source = sources[indexPath.row]
        let artist = self.artist
        
        return { SourceDetailsNode(source: source, inShow: show, artist: artist, atIndex: indexPath.row, isDetails: false) }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        guard let show = latestData else { return }

        let vc = SourceViewController(artist: artist, show: show, source: sources[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: State restoration
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
        case show = "show"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        do {
            if let artistData = coder.decodeObject(forKey: CodingKeys.artist.rawValue) as? Data,
               let showData = coder.decodeObject(forKey: CodingKeys.show.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let encodedShow = try JSONDecoder().decode(Show.self, from: showData)
                let vc = SourcesViewController(artist: encodedArtist, show: encodedShow)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let artistData = try JSONEncoder().encode(self.artist)
            coder.encode(artistData, forKey: CodingKeys.artist.rawValue)
            
            let encodedShow = try JSONEncoder().encode(self.show)
            coder.encode(encodedShow, forKey: CodingKeys.show.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}
