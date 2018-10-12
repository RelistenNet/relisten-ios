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
class SongsViewController: RelistenTableViewController<[SongWithShowCount]>, UISearchResultsUpdating {
    
    let artist: ArtistWithCounts
    var allSongs: SinqSequence<SongWithShowCount>?
    var songs: [Grouping<String, SongWithShowCount>] = []
    var filteredSongs: [Grouping<String, SongWithShowCount>] = []
    
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.tableNode.view.sectionIndexColor = AppColors.primary
        self.tableNode.view.sectionIndexMinimumDisplayRowCount = 4
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Songs"
        searchController.searchBar.barStyle = .blackTranslucent
        searchController.searchBar.barTintColor = AppColors.primary
        searchController.searchBar.tintColor = AppColors.textOnPrimary
        navigationItem.searchController = searchController
        definesPresentationContext = true
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
        allSongs = sinq(data)
        if let allSongs = allSongs {
            songs = allSongs
                .groupBy({
                    return $0.sortName.groupNameForTableView()
                })
                .toArray()
                .sorted(by: { (a, b) -> Bool in
                    return a.key <= b.key
                })
        }
    }
    
    func songForIndexPath(_ indexPath: IndexPath) -> SongWithShowCount? {
        var retval : SongWithShowCount? = nil
        let curSongs = searchBarIsEmpty() ? songs : filteredSongs
        
        if indexPath.section >= 0, indexPath.section < curSongs.count {
            let allSongs = curSongs[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allSongs.count() {
                retval = allSongs.elementAt(indexPath.row)
            }
        }
        return retval
    }
    
    //MARK: Table Data Source
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        if searchBarIsEmpty() {
            return songs.count
        } else {
            return filteredSongs.count
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if searchBarIsEmpty() {
            return songs[section].values.count()
        } else {
            return filteredSongs[section].values.count()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return nil
        }
        
        if searchBarIsEmpty() {
            return songs[section].key
        } else {
            return filteredSongs[section].key
        }
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchBarIsEmpty() {
            return songs.map({ return $0.key })
        } else {
            return filteredSongs.map({ return $0.key })
        }
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
    
    //MARK: Searching
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        let searchTextLC = searchText.lowercased()
        if let allSongs = allSongs {
            filteredSongs = allSongs.filter({ (song) -> Bool in
                    return song.name.lowercased().contains(searchTextLC)
                }).groupBy({
                    return $0.sortName.groupNameForTableView()
                })
                .toArray()
                .sorted(by: { (a, b) -> Bool in
                    return a.key <= b.key
                })
        } else {
            filteredSongs = []
        }
        tableNode.reloadData()
    }
    
    //MARK: UISearchResultsUpdating
    public func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
        }
    }
}
