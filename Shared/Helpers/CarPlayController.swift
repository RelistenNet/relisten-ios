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
    
    private var recentlyPlayedTracks: [Track] = []
    private var offlineShows: [OfflineSourceMetadata] = []
    private var favoriteShows: [CompleteShowInformation] = []
    
    enum Sections: Int, RawRepresentable {
        case recentlyPlayed = 0
        case availableOffline
        case favorite
        case artists
        case count
    }
    
    private func resizeImage(image : UIImage, newSize : CGSize) -> UIImage {
        return  UIGraphicsImageRenderer(size: newSize).image { (context) in
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        }
    }
    
    lazy var recentlyPlayedContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.RecentlyPlayed")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Recently Played"
        if let contentImage = UIImage(named: "carplay-recent") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: { [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    lazy var availableOfflineContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.AvailableOffline")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Downloads"
        if let contentImage = UIImage(named: "download-active") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: {  [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    lazy var favoritesContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.Favorites")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Favorites"
        if let contentImage = UIImage(named: "heart") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: {  [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    lazy var artistsContentItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.artists")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Artists"
        if let contentImage = UIImage(named: "carplay-artist") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: {  [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    func setup() {
        MPPlayableContentManager.shared().delegate = self;
        MPPlayableContentManager.shared().dataSource = self;
        
        PlaybackController.sharedInstance.observeCurrentTrack.observe { (current, _) in
            var nowPlayingIdentifiers : [String] = []
            if let current = current {
                nowPlayingIdentifiers.append(current.carPlayIdentifier)
            }
            MPPlayableContentManager.shared().nowPlayingIdentifiers = nowPlayingIdentifiers
        }.add(to: &disposal)
        
        MyLibraryManager.shared.observeRecentlyPlayedTracks.observe({ [weak self] tracks, _ in
            self?.reloadRecentTracks(tracks: tracks)
        }).add(to: &disposal)
        
        MyLibraryManager.shared.library.observeOfflineSources.observe({ [weak self] shows, _ in
            self?.reloadOfflineSources(shows: shows)
        }).add(to: &disposal)
        
        MyLibraryManager.shared.observeMyShows.observe({ [weak self] shows, _ in
            self?.reloadFavorites(shows: shows)
        }).add(to: &disposal)
    }
    
    // MARK: MPPlayableContentDelegate
//    public func playableContentManager(_ contentManager: MPPlayableContentManager, initializePlaybackQueueWithContentItems contentItems: [Any]?, completionHandler: @escaping (Error?) -> Swift.Void) {
//
//    }
    
//    public func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
//
//    }
    
    // MARK: MPPlayableContentDataSource
    public func numberOfChildItems(at indexPath: IndexPath) -> Int {
        if indexPath.count == 0 {
            return Sections.count.rawValue
        } else if indexPath.count == 1 {
            switch Sections(rawValue: indexPath[0])! {
            case .recentlyPlayed:
                return recentlyPlayedTracks.count
            case .availableOffline:
                return offlineShows.count
            case .favorite:
                return favoriteShows.count
            case .artists:
                return 0
            case .count:
                return 0
            }
        } else if indexPath.count == 2 {
            switch Sections(rawValue: indexPath[0])! {
            case .recentlyPlayed:
                return 0
            case .availableOffline:
                return offlineShows[indexPath[1]].source.tracksFlattened.count
            case .favorite:
                return 0
            case .artists:
                return 0
            case .count:
                return 0
            }
        }
        return 0
    }
    
    public func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        if indexPath.count == 1 {
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
        } else if indexPath.count == 2 {
            switch Sections(rawValue: indexPath[0])! {
            case .recentlyPlayed:
                return recentlyPlayedTracks[indexPath[1]].asMPContentItem()
            case .availableOffline:
                let offlineShow = offlineShows[indexPath[1]]
                return offlineShow.asMPContentItem()
            case .favorite:
                let favoriteShow = favoriteShows[indexPath[1]]
                return favoriteShow.asMPContentItem()
            case .artists:
                return self.artistsContentItem
            case .count:
                return nil
            }
        } else if indexPath.count == 3 {
            switch Sections(rawValue: indexPath[0])! {
            case .recentlyPlayed:
                return nil
            case .availableOffline:
                let offlineShow = offlineShows[indexPath[1]]
                let sourceTrack = offlineShow.source.tracksFlattened[indexPath[2]]
                let track = Track(sourceTrack: sourceTrack, showInfo: offlineShow.completeShowInformation)
                return track.asMPContentItem()
            case .favorite:
                let favoriteShow = favoriteShows[indexPath[1]]
                let sourceTrack = favoriteShow.source.tracksFlattened[indexPath[2]]
                let track = Track(sourceTrack: sourceTrack, showInfo: favoriteShow)
                return track.asMPContentItem()
            case .artists:
                return self.artistsContentItem
            case .count:
                return nil
            }
        }
        return nil
    }
    
    private func reloadRecentTracks(tracks: [Track]) {
        if !(tracks == recentlyPlayedTracks) {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.recentlyPlayedTracks = tracks
                MPPlayableContentManager.shared().endUpdates()
                MPPlayableContentManager.shared().reloadData()
            }
        }
    }
    
    private func reloadOfflineSources(shows: Set<OfflineSourceMetadata>) {
        let showArray = shows.map({ return $0 })
        if !(showArray == offlineShows) {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.offlineShows = showArray
                MPPlayableContentManager.shared().endUpdates()
                MPPlayableContentManager.shared().reloadData()
            }
        }
    }
    
    private func reloadFavorites(shows: [CompleteShowInformation]) {
        if !(shows == favoriteShows) {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.favoriteShows = shows
                MPPlayableContentManager.shared().endUpdates()
                MPPlayableContentManager.shared().reloadData()
            }
        }
    }
    
//    public func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
//        completionHandler(nil)
//    }
//
//    public func contentItem(forIdentifier identifier: String, completionHandler: @escaping (MPContentItem?, Error?) -> Swift.Void) {
//
//    }
    
    public func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        return true;
    }
}

extension Track {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.track.\(self.id)"
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
        contentItem.isStreamingContent = !(self.downloadState == .downloaded)
        contentItem.isExplicitContent = false
        contentItem.isContainer = false
        contentItem.isPlayable = true

        return contentItem
    }
}

extension OfflineSourceMetadata {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.offlinesource.\(self.hashValue)"
        }
    }
    
    public func asMPContentItem() -> MPContentItem {
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
        contentItem.title = self.show.display_date
        if let venueName = self.show.venue?.name {
            contentItem.subtitle = "\(self.artist.name) - \(venueName)"
        } else {
            contentItem.subtitle = self.artist.name
        }
        contentItem.isContainer = true
        contentItem.isPlayable = false
        
        return contentItem
    }
}

extension CompleteShowInformation {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.showinfo.\(self.hashValue)"
        }
    }
    
    public func asMPContentItem() -> MPContentItem {
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
        contentItem.title = self.show.display_date
        if let venueName = self.show.venue?.name {
            contentItem.subtitle = "\(self.artist.name) - \(venueName)"
        } else {
            contentItem.subtitle = self.artist.name
        }
        contentItem.isContainer = true
        contentItem.isPlayable = false
        
        return contentItem
    }
}
