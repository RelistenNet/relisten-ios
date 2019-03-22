//
//  SongViewController.swift
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

class SongViewController: ShowListViewController<SongWithShows>, UIViewControllerRestoration {
    let song: Song
    
    public required init(artist: Artist, song: Song) {
        self.song = song
        
        super.init(
            artist: artist,
            tourSections: false
        )
        
        self.restorationIdentifier = "net.relisten.SongViewController.\(artist.slug)"
        self.restorationClass = type(of: self)
        
        title = song.name
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    override public var resource: Resource? {
        get {
             return RelistenApi.shows(withPlayedSong: song, byArtist: artist)
        }
    }
    
    override func extractShowsAndSource(forData: SongWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil, artist: artist) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case song = "song"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: ShowListViewController<YearWithShows>.CodingKeys.artist.rawValue) as? Data,
                let songData = coder.decodeObject(forKey: CodingKeys.song.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let encodedSong = try JSONDecoder().decode(Song.self, from: songData)
                let vc = SongViewController(artist: encodedArtist, song: encodedSong)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let encodedSong = try JSONEncoder().encode(self.song)
            coder.encode(encodedSong, forKey: CodingKeys.song.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}
