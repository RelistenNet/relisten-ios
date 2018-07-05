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

class SourceViewController: RelistenBaseAsyncTableontroller {
    
    let artist: ArtistWithCounts
    let show: ShowWithSources
    let source: SourceFull
    let idx: Int
    
    let isInMyShows = Observable(false)
    let isAvailableOffline = Observable(false)

    lazy var addToMyShowsNode = SwitchCellNode(observeChecked: isInMyShows, withLabel: "Part of My Shows")
    lazy var downloadNode = SwitchCellNode(observeChecked: isAvailableOffline, withLabel: "Fully Available Offline")

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
        
        addSwitchListeners()
        
        let library = MyLibraryManager.shared.library
        
        library.observeOfflineSources.observe { [weak self] (new, old) in
            self?.isAvailableOffline.value = library.isSourceFullyAvailableOffline(source)
        }.add(to: &disposal)

        MyLibraryManager.shared.observeMyShows.observe { [weak self] (new, old) in
            guard let s = self else { return }
            
            s.isInMyShows.value = library.isShowInLibrary(show: s.show, byArtist: s.artist)
        }.add(to: &disposal)
        
        RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler({ [weak self] track in
            guard let s = self else { return }
            
            if track.showInfo.source.id == s.source.id {
                MyLibraryManager.shared.library.diskUsageForSource(source: s.completeShowInformation) { (size) in
                    s.rebuildOfflineSwitch(size)
                }
            }
        }).add(to: &disposal)
        
        RelistenDownloadManager.shared.eventTracksDeleted.addHandler({ [weak self] tracks in
            guard let s = self else { return }
            
            if tracks.any(match: { $0.showInfo.source.id == s.source.id }) {
                MyLibraryManager.shared.library.diskUsageForSource(source: s.completeShowInformation) { (size) in
                    s.rebuildOfflineSwitch(size)
                }
            }
        }).add(to: &disposal)
    }
    
    func rebuildOfflineSwitch(_ sourceSize: UInt64?) {
        let txt = "Fully Available Offline" + (sourceSize == nil ? "" : " (\(sourceSize!.humanizeBytes()))")
        downloadNode = SwitchCellNode(observeChecked: isAvailableOffline, withLabel: txt)
        addSwitchListeners()
        
        DispatchQueue.main.async {
            self.tableNode.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }
    }
    
    func addSwitchListeners() {
        addToMyShowsNode.observeUserChecked.removeAllObservers()
        downloadNode.observeUserChecked.removeAllObservers()
        
        addToMyShowsNode.observeUserChecked.observe(includingInitial: false) { (newValue, old) in
            if newValue {
                MyLibraryManager.shared.addShow(show: self.completeShowInformation)
            }
            else {
                let _ = MyLibraryManager.shared.removeShow(show: self.completeShowInformation)
            }
        }.add(to: &disposal)
        
        downloadNode.observeUserChecked.observe(includingInitial: false) { (newValue, old) in
            if newValue {
                // download whole show
                RelistenDownloadManager.shared.download(show: self.completeShowInformation)
            }
            else {
                // remove any downloaded tracks
                RelistenDownloadManager.shared.delete(showInfo: self.completeShowInformation)
            }
        }.add(to: &disposal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(show.display_date) #\(idx + 1)"
    }
    
    /*
    func doLayout(sourceSize: UInt64?) {
        let str = sourceSize == nil ? "" : " (\(sourceSize!.humanizeBytes()))"
        
        layout {
            var sections: [Section<[Layout]>] = [
                Section(items: [
                    SourceDetailsLayout(source: self.source, inShow: self.show, artist: self.artist, atIndex: self.idx),
                    SwitchCellLayout(title: "Part of My Shows", checkedByDefault: { self.isShowInLibrary }, onSwitch: self.onToggleAddToMyShows!),
                    SwitchCellLayout(title: "Fully Available Offline" + str, checkedByDefault: { self.isAvailableOffline }, onSwitch: self.onToggleOffline!),
                    ShareCellLayout()
                    ])
            ]
            
            sections.append(contentsOf: self.source.sets.map({ (set: SourceSet) -> Section<[Layout]> in
     let layouts = set.tracks.map({ TrackStatusLayout(withTrack: Track(sourceTrack: $0, showInfo: CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)), withHandler: self) })
                return LayoutsAsSingleSection(items: layouts, title: self.artist.features.sets ? set.name : "Tracks")
            }))
            
            return sections
        }
    }
     */
    
    var completeShowInformation: CompleteShowInformation {
        get {
            return CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)
        }
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1 + source.sets.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
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
                return { self.addToMyShowsNode }
            }
            else if indexPath.row == 2 {
                return { self.downloadNode }
            }
            else if indexPath.row == 3 {
                return { ShareCellNode() }
            }
        }
        
        let sourceTrack = source.sets[indexPath.section - 1].tracks[indexPath.row]
        let showInfo = CompleteShowInformation(source: source, show: show, artist: artist)
        let track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
        
        return { TrackStatusCellNode(withTrack: track, withHandler: self) }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            navigationController?.pushViewController(SourceDetailsViewController(artist: artist, show: show, source: source), animated: true)
            
            return
        }
        else if indexPath.section == 0 && indexPath.row == 3 {
            let show = completeShowInformation
            let activities: [Any] = [ShareHelper.text(forSource: show), ShareHelper.url(forSource: show)]
            
            let shareVc = UIActivityViewController(activityItems: activities, applicationActivities: nil)
            shareVc.modalTransitionStyle = .coverVertical
            
            if PlaybackController.sharedInstance.hasBarBeenAdded {
                PlaybackController.sharedInstance.viewController.present(shareVc, animated: true, completion: nil)
            }
            else {
                self.present(shareVc, animated: true, completion: nil)
            }
            
            return
        }
        else if indexPath.section == 0 {
            return
        }
        
        TrackActions.play(
            trackAtIndexPath: IndexPath(row: indexPath.row, section: indexPath.section - 1),
            inShow: completeShowInformation,
            fromViewController: self
        )
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        return self.artist.features.sets ? source.sets[section - 1].name : "Tracks"
    }
}

extension SourceViewController : TrackStatusActionHandler {
    func trackButtonTapped(_ button: UIButton, forTrack track: Track) {
        TrackActions.showActionOptions(fromViewController: self, forTrack: track)
    }
}
