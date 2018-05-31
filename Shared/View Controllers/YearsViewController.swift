//
//  YearsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import LayoutKit
import SINQ

class YearsViewController: RelistenTableViewController<[Year]> {
    
    let artist: ArtistWithCounts
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Years"

        trackFinishedHandler = RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(target: self, handler: YearsViewController.relayoutIfContainsTrack)
        tracksDeletedHandler = RelistenDownloadManager.shared.eventTracksDeleted.addHandler(target: self, handler: YearsViewController.relayoutIfContainsTracks)
    }
    
    var trackFinishedHandler: Disposable?
    var tracksDeletedHandler: Disposable?
    
    deinit {
        for handler in [trackFinishedHandler, tracksDeletedHandler] {
            handler?.dispose()
        }
    }
    
    func relayoutIfContainsTrack(_ track: CompleteTrackShowInformation) {
        if artist.id == track.artist.id, let d = latestData {
            render(forData: d)
        }
    }
    
    func relayoutIfContainsTracks(_ tracks: [CompleteTrackShowInformation]) {
        if sinq(tracks).any({ $0.artist.id == artist.id }), let d = latestData {
            render(forData: d)
        }
    }
    
    override var resource: Resource? { get { return api.years(byArtist: artist) } }
    
    override func render(forData: [Year]) {
        layout {
            return forData.map { YearLayout(year: $0) }.asTable()
        }
    }
    
    override func has(oldData: [Year], changed: [Year]) -> Bool {
        return oldData.count != changed.count
    }
    
    override func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let d = latestData {
            navigationController?.pushViewController(YearViewController(artist: artist, year: d[indexPath.row]), animated: true)
        }
    }
}
