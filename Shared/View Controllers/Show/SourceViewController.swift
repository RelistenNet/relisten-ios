//
//  SourceViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 6/6/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import Observable
import SINQ

public class SourceViewController: RelistenBaseAsyncTableViewController {
    
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
        super.viewDidLoad()
        
        if show.sources.count == 1 {
            title = "\(show.display_date)"
        } else {
            title = "\(show.display_date) #\(idx + 1)"
        }
    }
    
    // MARK: UITableViewDelegate
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1 + source.sets.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        
        return source.sets[section - 1].tracks.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let artist = self.artist
        let source = self.source
        let show = self.show
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return { SourceDetailsNode(source: source, inShow: show, artist: artist, atIndex: indexPath.row, isDetails: true) }
            }
            else if indexPath.row == 1 {
                return { UserPropertiesForShowNode(source: source, inShow: show, artist: artist, shareSheetController: self) }
            }
        }
        
        let sourceTrack = source.sets[indexPath.section - 1].tracks[indexPath.row]
        let showInfo = CompleteShowInformation(source: source, show: show, artist: artist)
        let track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
        
        return { TrackStatusCellNode(withTrack: track, withHandler: self) }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Don't highlight taps on the "my shows"/downloads cells, since they require a tap on the switch
        if indexPath.section == 0, indexPath.row == 1 {
            return false
        } else {
            return true
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            switch indexPath.row {
                case 0:
                    navigationController?.pushViewController(SourceDetailsViewController(artist: artist, show: show, source: source), animated: true)
                default:
                    break
            }
        }
        
        if indexPath.section > 0 {
            TrackActions.play(
                trackAtIndexPath: IndexPath(row: indexPath.row, section: indexPath.section - 1),
                inShow: completeShowInformation,
                fromViewController: self
            )
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        return self.artist.features.sets ? source.sets[section - 1].name : "Tracks"
    }
}

extension SourceViewController : TrackStatusActionHandler {
    public func trackButtonTapped(_ button: UIButton, forTrack track: Track) {
        TrackActions.showActionOptions(fromViewController: self, forTrack: track)
    }
}
