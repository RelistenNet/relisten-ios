//
//  SongsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 9/20/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

// TODO: Combine this with VenuesViewController into something more abstract. The code is practically identical
class SongsViewController: RelistenTableViewController<[SongWithShowCount]> {
    
    let artist: ArtistWithCounts
    var songs: [Grouping<String, SongWithShowCount>] = []
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Songs"
    }
    
    override var resource: Resource? { get { return api.songs(byArtist: artist) } }
    
    public override func dataChanged(_ data: [SongWithShowCount]) {
        songs = sinq(data)
            .groupBy({
                return $0.sortName.groupNameForTableView()
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
        })
    }
    
    func songForIndexPath(_ indexPath: IndexPath) -> SongWithShowCount? {
        var retval : SongWithShowCount? = nil
        if indexPath.section >= 0, indexPath.section < songs.count {
            let allSongs = songs[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allSongs.count() {
                retval = allSongs.elementAt(indexPath.row)
            }
        }
        return retval
    }
    
    //MARK: Table Data Source
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return songs.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return songs[section].values.count()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        return songs[section].key
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        if let song = songForIndexPath(indexPath) {
            return { SongNode(song: song) }
        } else {
            return { ASCellNode() }
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if let song = songForIndexPath(indexPath) {
            navigationController?.pushViewController(SongViewController(artist: artist, song: song), animated: true)
        }
    }
}
