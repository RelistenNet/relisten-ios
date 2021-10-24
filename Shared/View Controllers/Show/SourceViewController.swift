//
//  SourceViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 6/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit
import SafariServices

import Siesta
import AsyncDisplayKit
import Observable
import SINQ

public class SourceViewController: RelistenBaseTableViewController {
    
    private let artist: ArtistWithCounts
    private let show: ShowWithSources
    private let source: SourceFull
    private let idx: Int
    
    public let isInMyShows = Observable(false)
    public let isAvailableOffline = Observable(false)

    private lazy var completeShowInformation = CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)

    public required init(artist: ArtistWithCounts, show: ShowWithSources, source: SourceFull) {
        self.artist = artist
        self.show = show
        self.source = source
        
        var idx = 0
        
        for src in show.sources {
            if self.source.id == src.id {
                break
            }
            idx += 1
        }
        
        self.idx = idx
        
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        if artist.name == "Phish" {
            AppColors_SwitchToPhishOD()
        }
        else {
            AppColors_SwitchToRelisten()
        }
        
        super.viewDidLoad()
        
        if show.sources.count == 1 {
            title = "\(show.display_date)"
        } else {
            title = "\(show.display_date) #\(idx + 1)"
        }
        
        if show.sources.count > 1 {
            if let navigationController = navigationController,
               !(navigationController.viewControllers[navigationController.viewControllers.count - 2] is SourcesViewController) {
                let sourcesItem = UIBarButtonItem(title: "All Sources", style: .plain, target: self, action: #selector(sourcesNavItemTapped(_:)))
                self.navigationItem.rightBarButtonItem = sourcesItem
            }
        }
    }
    
    @objc public func sourcesNavItemTapped(_ sender: UINavigationBar?) {
        navigationController?.pushViewController(SourcesViewController(artist: artist, show: show), animated: true)
    }
    
    // MARK: UITableViewDelegate
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 2 + source.sets.count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        
        if section == 1 + source.sets.count {
            return source.links.count
        }
        
        return source.sets[section - 1].tracks.count
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let artist = self.artist
        let source = self.source
        let show = self.show
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return { SourceDetailsNode(source: source, inShow: show, artist: artist, atIndex: indexPath.row, isDetails: true) }
            }
            else if indexPath.row == 1 {
                return { UserPropertiesForShowNode(source: source, inShow: show, artist: artist, viewController: self) }
            }
        }
        
        if indexPath.section == 1 + source.sets.count {
            let link = source.links[indexPath.row]
            let upstreamSource = artist.upstream_sources.first(where: { $0.upstream_source_id == link.upstream_source_id })
            
            return { LinkUpstreamNode(forLink: link, fromUpstreamSource: upstreamSource?.upstream_source) }
        }
        
        let sourceTrack = source.sets[indexPath.section - 1].tracks[indexPath.row]
        let showInfo = CompleteShowInformation(source: source, show: show, artist: artist)
        let track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
        
        return { TrackStatusCellNode(withTrack: track, withHandler: self) }
    }
    
    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Don't highlight taps on the "my shows"/downloads cells, since they require a tap on the switch
        if indexPath.section == 0, indexPath.row == 1 {
            return false
        } else {
            return true
        }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            switch indexPath.row {
                case 0:
                    navigationController?.pushViewController(SourceDetailsViewController(artist: artist, show: show, source: source), animated: true)
                default:
                    break
            }
        }
        
        if indexPath.section == 1 + source.sets.count {
            let link = source.links[indexPath.row]
            let secureLink = link.url.replacingOccurrences(of: "http:", with: "https:")
            navigationController?.present(SFSafariViewController(url: URL(string: secureLink)!), animated: true, completion: nil)
            return
        }
        
        if indexPath.section > 0 {
            TrackActions.play(
                trackAtIndexPath: IndexPath(row: indexPath.row, section: indexPath.section - 1),
                inShow: completeShowInformation,
                fromViewController: self
            )
        }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        if section == 1 + source.sets.count {
            return "Data/Source Credits"
        }
        
        return self.artist.features.sets ? source.sets[section - 1].name : "Tracks"
    }
}

extension SourceViewController : TrackStatusActionHandler {
    public func trackButtonTapped(_ button: UIButton, forTrack track: Track) {
        TrackActions.showActionOptions(fromViewController: self, inView: button, forTrack: track)
    }
}
