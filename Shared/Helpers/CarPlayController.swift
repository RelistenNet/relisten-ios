//
//  CarPlayController.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/6/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import MediaPlayer
import Observable

public class CarPlayController : NSObject, MPPlayableContentDelegate, MPPlayableContentDataSource {
    static let shared = CarPlayController()
    var disposal = Disposal()
    
    enum Sections: Int, RawRepresentable {
        case recentlyPlayed = 0
        case availableOffline
        case favorite
        case artists
        case count
    }
    
    lazy var recentlyPlayedContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.RecentlyPlayed")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Recently Played"
        return contentItem
    }()
    
    lazy var availableOfflineContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.AvailableOffline")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Downloads"
        return contentItem
    }()
    
    lazy var favoritesContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.Favorites")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Favorites"
        return contentItem
    }()
    
    lazy var artistsContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.artists")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Artists"
        return contentItem
    }()
    
    override init() {
        super.init()
        
        MPPlayableContentManager.shared().dataSource = self;
        MPPlayableContentManager.shared().delegate = self;
        
        PlaybackController.sharedInstance.observeCurrentTrack.observe { (current, _) in
            var nowPlayingIdentifiers : [String] = []
            if let current = current {
                nowPlayingIdentifiers.append(current.carPlayIdentifier)
            }
            MPPlayableContentManager.shared().nowPlayingIdentifiers = nowPlayingIdentifiers
        }.add(to: &disposal)
    }
    
    // MARK: MPPlayableContentDelegate
    public func playableContentManager(_ contentManager: MPPlayableContentManager, initializePlaybackQueueWithContentItems contentItems: [Any]?, completionHandler: @escaping (Error?) -> Swift.Void) {
        
    }
    public func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
        
    }
    
    // MARK: MPPlayableContentDataSource
    public func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 4
    }
    
    public func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        //let row = indexPath.row
        
        switch Sections(rawValue: indexPath[0])! {
        case .recentlyPlayed:
            return self.recentlyPlayedContentItem
        case .availableOffline:
            return self.availableOfflineContentItem
        case .favorite:
            return self.favoritesContentItem
        case .artists:
            return self.artistsContentItem
        case .count:
            return nil
        }
    }
    
    public func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
        
    }
    
    public func contentItem(forIdentifier identifier: String, completionHandler: @escaping (MPContentItem?, Error?) -> Swift.Void) {
        
    }
    
    public func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        return true;
    }
}

extension Track {
    public var carPlayIdentifier : String {
        get {
            return "\(self.id)"
        }
    }
    public func asMPContentItem() -> MPContentItem {
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
        contentItem.title = self.title
        if let venueName = self.showInfo.show.venue?.name {
            contentItem.subtitle = "\(self.showInfo.artist.name) - \(venueName)"
        } else {
            contentItem.subtitle = self.showInfo.artist.name
        }
        contentItem.isStreamingContent = (self.downloadState == .downloaded)
        contentItem.isExplicitContent = false
        contentItem.isContainer = false
        contentItem.isPlayable = true

        return contentItem
    }
}
