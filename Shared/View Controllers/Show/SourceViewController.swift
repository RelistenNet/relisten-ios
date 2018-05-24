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
                MyLibraryManager.shared.addShow(show: self.show, byArtist: self.artist)
            }
            else {
                let _ = MyLibraryManager.shared.removeShow(show: self.show, byArtist: self.artist)
            }
        }
        
        onToggleOffline = { (newValue: Bool) in
            if newValue {
                // download whole show
                RelistenDownloadManager.shared.download(show: self.completeShowInformation)

                self.isAvailableOffline = true
            }
            else {
                // remove any downloaded tracks
                self.isAvailableOffline = false
                
                RelistenDownloadManager.shared.delete(source: self.source)
            }
        }

        trackStartedHandler = RelistenDownloadManager.shared.eventTrackStartedDownloading.addHandler(target: self, handler: SourceViewController.relayoutIfContainsTrack)
        tracksQueuedHandler = RelistenDownloadManager.shared.eventTracksQueuedToDownload.addHandler(target: self, handler: SourceViewController.relayoutIfContainsTracks)
        trackFinishedHandler = RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(target: self, handler: SourceViewController.relayoutIfContainsTrack)
        tracksDeletedHandler = RelistenDownloadManager.shared.eventTracksDeleted.addHandler(target: self, handler: SourceViewController.relayoutIfContainsTracks)
        trackPlaybackChangedHandler = PlaybackController.sharedInstance.eventTrackPlaybackChanged.addHandler(target: self, handler: SourceViewController.relayoutIfCompleteContainsTrack)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    var trackStartedHandler: Disposable?
    var tracksQueuedHandler: Disposable?
    var trackFinishedHandler: Disposable?
    var tracksDeletedHandler: Disposable?
    var trackPlaybackChangedHandler: Disposable?

    deinit {
        for handler in [trackStartedHandler, tracksQueuedHandler, trackFinishedHandler, tracksDeletedHandler, trackPlaybackChangedHandler] {
            handler?.dispose()
        }
    }

    var isShowInLibrary: Bool = false
    var isAvailableOffline: Bool = false

    var onToggleAddToMyShows: ((Bool) -> Void)? = nil
    var onToggleOffline: ((Bool) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(show.display_date) #\(idx + 1)"
        
        relayout()
    }
    
    func relayoutIfContainsTrack(_ track: SourceTrack) {
        if source.tracksFlattened.contains(where: { $0 === track }) {
            relayout()
        }
    }
    
    func relayoutIfCompleteContainsTrack(_ complete: CompleteTrackShowInformation?) {
        if complete == nil || source.id == complete!.source.id {
            relayout()
        }
    }
    
    func relayoutIfContainsTracks(_ tracks: [SourceTrack]) {
        if source.tracksFlattened.contains(where: { outer in tracks.contains(where: { inner in outer === inner })  }) {
            relayout()
        }
    }

    func relayout() {
        isAvailableOffline = MyLibraryManager.shared.library.isSourceFullyAvailableOffline(source: self.source)
        isShowInLibrary = MyLibraryManager.shared.library.isShowInLibrary(show: self.show, byArtist: self.artist)

        if isAvailableOffline {
            MyLibraryManager.shared.library.diskUsageForSource(source: self.source) { (size) in
                DispatchQueue.main.async {
                    self.doLayout(sourceSize: size)
                }
            }
        }
        else {
            doLayout(sourceSize: nil)
        }
    }
    
    func doLayout(sourceSize: UInt64?) {
        let str = sourceSize == nil ? "" : " (\(sourceSize!.humanizeBytes()))"
        
        layout {
            var sections: [Section<[Layout]>] = [
                Section(items: [
                    SourceDetailsLayout(source: self.source, inShow: self.show, artist: self.artist, atIndex: self.idx),
                    SwitchCellLayout(title: "Part of My Shows", checkedByDefault: { self.isShowInLibrary }, onSwitch: self.onToggleAddToMyShows!),
                    SwitchCellLayout(title: "Fully Available Offline" + str, checkedByDefault: { self.isAvailableOffline }, onSwitch: self.onToggleOffline!)
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
