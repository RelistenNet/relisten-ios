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
import LayoutKit
import SINQ

class SourceViewController: RelistenBaseTableViewController {
    
    let artist: SlimArtistWithFeatures
    let show: ShowWithSources
    let source: SourceFull
    let idx: Int
    
    public required init(artist: SlimArtistWithFeatures, show: ShowWithSources, source: SourceFull) {
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
        
        onToggleAddToMyShows = { (newValue: Bool) in
            self.isShowInLibrary = newValue
            if newValue {
                MyLibraryManager.sharedInstance.addShow(show: self.show, byArtist: self.artist)
            }
            else {
                let _ = MyLibraryManager.sharedInstance.removeShow(show: self.show, byArtist: self.artist)
            }
        }
        
        onToggleOffline = { (newValue: Bool) in
            if newValue {
                // download whole show
                RelistenDownloadManager.sharedInstance.download(show: self.completeShowInformation)

                self.isAvailableOffline = true
            }
            else {
                // remove any downloaded tracks
            }
        }

        isShowInLibrary = MyLibraryManager.sharedInstance.isShowInLibrary(show: self.show, byArtist: self.artist)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    var isShowInLibrary: Bool = false
    var isAvailableOffline: Bool = false

    var onToggleAddToMyShows: ((Bool) -> Void)? = nil
    var onToggleOffline: ((Bool) -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(show.display_date) #\(idx + 1)"
        
        layout {
            var sections: [Section<[Layout]>] = [
                Section(items: [
                    SourceDetailsLayout(source: self.source, inShow: self.show, artist: self.artist, atIndex: self.idx),
                    SwitchCellLayout(title: "Add to My Shows", checkedByDefault: { self.isShowInLibrary }, onSwitch: self.onToggleAddToMyShows!),
                    SwitchCellLayout(title: "Available Offline", checkedByDefault: { self.isAvailableOffline }, onSwitch: self.onToggleOffline!)
                ])
            ]
            
            sections.append(contentsOf: self.source.sets.map({ (set: SourceSet) -> Section<[Layout]> in
                let layouts = set.tracks.map({ TrackStatusLayout(withTrack: CompleteTrackShowInformation(track: TrackStatus(forTrack: $0), source: self.source, show: self.show, artist: self.artist), withHandler: self) })
                return LayoutsAsSingleSection(items: layouts, title: self.artist.features.sets ? set.name : "Tracks")
            }))
            
            return sections
        }
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            cell.selectionStyle = .none
        }
        
        cell.accessoryType = .none
        
        return cell
    }
    
    var completeShowInformation: CompleteShowInformation {
        get {
            return CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section != 0 else {
            return
        }
        
        TrackActions.play(
            trackAtIndexPath: IndexPath(row: indexPath.row, section: indexPath.section - 1),
            inShow: completeShowInformation,
            fromViewController: self
        )
    }
}

extension SourceViewController : TrackStatusActionHandler {
    func trackButtonTapped(_ button: UIButton, forTrack track: CompleteTrackShowInformation) {
        TrackActions.showActionOptions(fromViewController: self, forTrack: track)
    }
}
