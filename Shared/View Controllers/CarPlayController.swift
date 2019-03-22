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
import Siesta
import UIKit
import CoreGraphics

public class CarPlayController : NSObject, MPPlayableContentDelegate, MPPlayableContentDataSource, CarPlayDataSourceDelegate {
    public static let shared = CarPlayController()
    public static let albumArtEnabled = false
    
    private let queue : ReentrantDispatchQueue = ReentrantDispatchQueue(label: "live.relisten.ios.carplay.queue")
    private var backingDataSource : CarPlayDataSource?
    private lazy var dataSource : CarPlayDataSource = {
        if (backingDataSource == nil) {
            queue.sync {
                if (backingDataSource == nil) {
                    backingDataSource = CarPlayDataSource(delegate: self)
                }
            }
        }
        return backingDataSource!
    }()
    
    private var disposal = Disposal()
    
    // MARK: Setup
    
    public func setup() {
        MPPlayableContentManager.shared().delegate = self;
        MPPlayableContentManager.shared().dataSource = self;
        
        RelistenApp.sharedApp.playbackController.observeCurrentTrack.observe { (current, _) in
            var nowPlayingIdentifiers : [String] = []
            if let current = current {
                nowPlayingIdentifiers.append(current.carPlayIdentifier)
            }
            MPPlayableContentManager.shared().nowPlayingIdentifiers = nowPlayingIdentifiers
        }.add(to: &disposal)
    }
    
    func carPlayDataSourceWillUpdate() {
        performOnMainQueueSync({
            MPPlayableContentManager.shared().beginUpdates()
        })
    }
    
    func carPlayDataSourceDidUpdate() {
        performOnMainQueueSync {
            MPPlayableContentManager.shared().endUpdates()
            MPPlayableContentManager.shared().reloadData()
        }
    }
    
    // MARK: Tab Headers
    private func resizeImage(image : UIImage, newSize : CGSize) -> UIImage {
        if image.size == newSize {
            return image
        } else {
            return  UIGraphicsImageRenderer(size: newSize).image { (context) in
                image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            }
        }
    }
    
    lazy var recentlyPlayedTabBarItem : MPContentItem = {
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
    
    lazy var availableOfflineTabBarItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.AvailableOffline")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Downloads"
        if let contentImage = UIImage(named: "carplay-download") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: {  [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    lazy var favoritesTabBarItem : MPContentItem = {
        let contentItem = MPContentItem(identifier: "live.relisten.Favorites")
        contentItem.isPlayable = false
        contentItem.isContainer = true
        contentItem.title = "Favorites"
        if let contentImage = UIImage(named: "carplay-heart") {
            contentItem.artwork = MPMediaItemArtwork(boundsSize: contentImage.size, requestHandler: {  [unowned self] (size) -> UIImage in
                return self.resizeImage(image: contentImage, newSize: size)
            })
        }
        return contentItem
    }()
    
    lazy var artistsTabBarItem : MPContentItem = {
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
    
    // MARK: MPPlayableContentDelegate
//    public func playableContentManager(_ contentManager: MPPlayableContentManager, initializePlaybackQueueWithContentItems contentItems: [Any]?, completionHandler: @escaping (Error?) -> Swift.Void) {
//
//    }
    
    public func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
        let section = CarPlaySection(rawValue: indexPath[0])!
        var track : Track?
        
        switch section {
        case .recentlyPlayed:
            (_, track) = recentShowItems(at: indexPath)
            
        case .availableOffline:
            (_, _, _, track) = offlineItems(at: indexPath)
            
        case .favorite:
            (_, _, _, track) = favoriteItems(at: indexPath)
            
        case .artists:
            // Artists->Artists
            (_, _, _, _, _, _, track) = allArtistItems(at: indexPath)
            break
            
        case .count:
            break
        }
        
        if let track = track {
            if let viewController = RelistenApp.sharedApp.delegate.rootNavigationController.topViewController {
                DispatchQueue.main.async {
                    TrackActions.play(track: track, fromViewController: viewController)
                    DispatchQueue.global(qos: .userInitiated).async {
                        completionHandler(nil)
                    }
                }
            } else {
                // TODO: We should probably still play the track in this case
                NSLog("🚗 Couldn't get the topmost view controller. Skipping playback.")
                // TODO: Create a real error
                completionHandler(nil)
            }
        } else {
            NSLog("🚗 Invalid index path for playback: \(indexPath)")
            // TODO: Create a real error
            completionHandler(nil)
        }
    }
    
    // MARK: MPPlayableContentDataSource
    enum CarPlaySection: Int, RawRepresentable {
        case recentlyPlayed = 0
        case availableOffline
        case favorite
        case artists
        case count
    }
    
    private func carPlaySection(from indexPath: IndexPath) -> CarPlaySection? {
        if indexPath.count > 0 {
            let rawSection : Int = indexPath[0]
            // TODO: base this off the actual enum values instead of hardcoded numbers
            if rawSection >= 0, rawSection < 4 {
                return CarPlaySection(rawValue: rawSection)
            }
        }
        return nil
    }
    
    private func recentShowItems(at indexPath: IndexPath) -> (CompleteShowInformation?, Track?) {
        var showInfo : CompleteShowInformation?
        var track : Track?
        if carPlaySection(from: indexPath) == .recentlyPlayed {
            if indexPath.count > 1 {
                showInfo = dataSource.recentlyPlayedShows().objectAtIndexIfInBounds(indexPath[1])
            }
            if indexPath.count > 2 {
                if let showInfo = showInfo {
                    if let sourceTrack = showInfo.source.tracksFlattened.objectAtIndexIfInBounds(indexPath[2]) {
                        track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
                    }
                }
            }
        }
        
        return (showInfo, track)
    }
    
    private func offlineItems(at indexPath: IndexPath) -> (Artist?, showCount: Int?, CompleteShowInformation?, Track?) {
        var artist : Artist?
        var showCount : Int?
        var allShows : [CompleteShowInformation]?
        var offlineMetadata : CompleteShowInformation?
        var track : Track?
        if carPlaySection(from: indexPath) == .availableOffline {
            if indexPath.count > 1 {
                artist = dataSource.artistsWithOfflineShows().objectAtIndexIfInBounds(indexPath[1])
                if let artist = artist {
                    allShows = dataSource.offlineShowsForArtist(artist)
                    if let allShows = allShows {
                        showCount = allShows.count
                    }
                }
            }
            if indexPath.count > 2 {
                if let allShows = allShows {
                    offlineMetadata = allShows.objectAtIndexIfInBounds(indexPath[2])
                }
            }
            if indexPath.count > 3 {
                if let offlineMetadata = offlineMetadata {
                    if let sourceTrack = offlineMetadata.source.tracksFlattened.objectAtIndexIfInBounds(indexPath[3]) {
                        track = Track(sourceTrack: sourceTrack, showInfo: offlineMetadata)
                    }
                }
            }
        }
        
        return (artist, showCount, offlineMetadata, track)
    }
    
    private func favoriteItems(at indexPath: IndexPath) -> (Artist?, showCount : Int?, CompleteShowInformation?, Track?) {
        var artist : Artist?
        var showCount : Int?
        var shows : [CompleteShowInformation]?
        var show : CompleteShowInformation?
        var track : Track?
        if carPlaySection(from: indexPath) == .favorite {
            if indexPath.count > 1 {
                artist = dataSource.artistsWithFavoritedShows().objectAtIndexIfInBounds(indexPath[1])
                if let artist = artist {
                    shows = dataSource.favoriteShowsForArtist(artist)
                    if let shows = shows {
                        showCount = shows.count
                    }
                }
            }
            if indexPath.count > 2 {
                if let shows = shows {
                    show = shows.objectAtIndexIfInBounds(indexPath[2])
                }
            }
            if indexPath.count > 3 {
                if let show = show {
                    if let sourceTrack = show.source.tracksFlattened.objectAtIndexIfInBounds(indexPath[3]) {
                        track = Track(sourceTrack: sourceTrack, showInfo: show)
                    }
                }
            }
        }
        return (artist, showCount, show, track)
    }
    
    private func allArtistItems(at indexPath: IndexPath) -> (ArtistWithCounts?, yearCount: Int?, Year?, showCount: Int?, Show?, CompleteShowInformation?, Track?) {
        var artist : ArtistWithCounts?
        var yearCount : Int?
        var years : [Year]?
        var year : Year?
        var shows : [Show]?
        var showCount : Int?
        var show : Show?
        var showInfo : CompleteShowInformation?
        var track : Track?
        let block = {
            if self.carPlaySection(from: indexPath) == .artists {
                if indexPath.count > 1 {
                    artist = self.dataSource.allArtists().objectAtIndexIfInBounds(indexPath[1])
                    if let artist = artist {
                        showCount = artist.show_count
                        
                        years = self.dataSource.years(forArtist: artist)
                        if let y = years {
                            yearCount = y.count
                        }
                    }
                }
                if let artist = artist {
                    if indexPath.count > 2 {
                        if let years = years {
                            year = years.objectAtIndexIfInBounds(indexPath[2])
                            
                            if let year = year {
                                shows = self.dataSource.shows(forArtist: artist, inYear: year)
                                if let shows = shows {
                                    showCount = shows.count
                                }
                            }
                        }
                    }
                    if indexPath.count > 3 {
                        if let shows = shows {
                            show = shows.objectAtIndexIfInBounds(indexPath[3])
                            if let show = show {
                                showInfo = self.dataSource.completeShow(forArtist: artist, show: show)
                            }
                        }
                    }
                    if indexPath.count > 4 {
                        if let showInfo = showInfo {
                            if let sourceTrack = showInfo.source.tracksFlattened.objectAtIndexIfInBounds(indexPath[4]) {
                                track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
                            }
                        }
                    }
                }
            }
        }
        performOnMainQueueSync(block)
        return (artist, yearCount, year, showCount, show, showInfo, track)
    }
    
    public func numberOfChildItems(at indexPath: IndexPath) -> Int {
        guard let section = carPlaySection(from: indexPath) else {
            if indexPath.count == 0 {
                return CarPlaySection.count.rawValue
            }
            return 0
        }
        
        switch indexPath.count {
        case 0:
            // Tab Bar
            return CarPlaySection.count.rawValue
        case 1:
            // I wish we could unlock the data when the user goes back to the top level view but there's just no way to do that with the current MPPlayableContentManager API. The best we can do is unlock here, which will unlock if the user switches tabs
            DispatchQueue.main.async {
                // This might cause the table data to reload. Defer that until after this function is done
                self.dataSource.unlockData()
            }
            
            switch section {
            case .recentlyPlayed:
                // Recent->Shows
                return dataSource.recentlyPlayedShows().count
                
            case .availableOffline:
                // Offline->Artists
                return dataSource.artistsWithOfflineShows().count
                
            case .favorite:
                // Favorites->Artists
                return dataSource.artistsWithFavoritedShows().count
                
            case .artists:
                // Artists->Artists
                return dataSource.allArtists().count
                
            case .count:
                return 0
            }
        case 2:
            dataSource.lockData()
            switch section {
            case .recentlyPlayed:
                // Recent->Show->Tracks
                let (show, _) = recentShowItems(at: indexPath)
                if let show = show {
                    return show.source.tracksFlattened.count
                }
                
            case .availableOffline:
                // Offline->Artist->Shows
                let (_, showCount, _, _) = offlineItems(at: indexPath)
                if let showCount = showCount {
                    return showCount
                }
                
            case .favorite:
                // Favorites->Artist->Shows
                let (_, showCount, _, _) = favoriteItems(at: indexPath)
                if let showCount = showCount {
                    return showCount
                }
                
            case .artists:
                // Artists->Artist->Years
                let (_, yearCount, _, _, _, _, _) = allArtistItems(at: indexPath)
                if let yearCount = yearCount {
                    return yearCount
                }
                
            case .count:
                return 0
            }
        case 3:
            switch section {
            case .availableOffline:
                // Offline->Artist->Shows->Tracks
                let (_, _, offlineMetadata, _) = offlineItems(at: indexPath)
                if let offlineMetadata = offlineMetadata {
                    return offlineMetadata.source.tracksFlattened.count
                }
                
            case .favorite:
                // Favorites->Artist->Show->Tracks
                let (_, _, show, _) = favoriteItems(at: indexPath)
                if let show = show {
                    return show.source.tracksFlattened.count
                }
                
            case .artists:
                // Artists->Artist->Year->Shows
                let (_, _, _, showCount, _, _, _) = allArtistItems(at: indexPath)
                if let showCount = showCount {
                    return showCount
                }
                
            default:
                return 0
            }
        case 4:
            switch section {
            case .artists:
                // Artists->Artist->Year->Show->Tracks
                let (_, _, _, _, _, showInfo, _) = allArtistItems(at: indexPath)
                if let showInfo = showInfo {
                    return showInfo.source.tracksFlattened.count
                }
            default:
                return 0
            }
        default:
            return 0
        }
        return 0
    }
    
    private func tabBarItem(for section: CarPlaySection) -> MPContentItem? {
        switch section {
        case .recentlyPlayed:
            return self.recentlyPlayedTabBarItem
        case .availableOffline:
            return self.availableOfflineTabBarItem
        case .favorite:
            return self.favoritesTabBarItem
        case .artists:
            return self.artistsTabBarItem
        case .count:
            return nil
        }
    }
    
    public func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        guard let section = carPlaySection(from: indexPath) else {
            return nil
        }
        
        switch indexPath.count {
        case 1:
            return tabBarItem(for: section)
        case 2:
            switch section {
            case .recentlyPlayed:
                // Recent->Shows
                let (show, _) = recentShowItems(at: indexPath)
                if let show = show {
                    return show.asMPContentItem()
                }
                
            case .availableOffline:
                // Offline->Artists
                let (artist, showCount, _, _) = offlineItems(at: indexPath)
                if let artist = artist {
                    return artist.asMPContentItem(withShowCount: showCount)
                }
                
            case .favorite:
                // Favorites->Artists
                let (artist, showCount, _, _) = favoriteItems(at: indexPath)
                if let artist = artist {
                    return artist.asMPContentItem(withShowCount: showCount)
                }
                
            case .artists:
                // Artists->Artists
                let (artist, _, _, _, _, _, _) = allArtistItems(at: indexPath)
                if let artist = artist {
                    return artist.asMPContentItem(withShowCount: artist.show_count)
                }
                
            case .count:
                return nil
            }
        case 3:
            switch section {
            case .recentlyPlayed:
                // Recent->Show->Tracks
                let (_, track) = recentShowItems(at: indexPath)
                if let track = track {
                    return track.asMPContentItem()
                }
                
            case .availableOffline:
                // Offline->Artist->Shows
                let (_, _, offlineMetadata, _) = offlineItems(at: indexPath)
                if let offlineMetadata = offlineMetadata {
                    return offlineMetadata.asMPContentItem()
                }
                
            case .favorite:
                // Favorites->Artist->Shows
                let (_, _, show, _) = favoriteItems(at: indexPath)
                if let show = show {
                    return show.asMPContentItem()
                }
                
            case .artists:
                // Artists->Artist->Years
                let (_, _, year, _, _, _, _) = allArtistItems(at: indexPath)
                if let year = year {
                    return year.asMPContentItem()
                }
                
            case .count:
                return nil
            }
        case 4:
            switch section {
            case .availableOffline:
                // Offline->Artist->Shows->Tracks
                let (_, _, _, track) = offlineItems(at: indexPath)
                if let track = track {
                    return track.asMPContentItem()
                }
                
            case .favorite:
                // Favorites->Artist->Show->Tracks
                let (_, _, _, track) = favoriteItems(at: indexPath)
                if let track = track {
                    return track.asMPContentItem()
                }
                
            case .artists:
                // Artists->Artist->Year->Shows
                let (_, _, _, _, show, _, _) = allArtistItems(at: indexPath)
                if let show = show {
                    return show.asMPContentItem()
                }
                
            default:
                return nil
            }
        case 5:
            switch section {
            case .artists:
                // Artists->Artist->Year->Show->Tracks
                let (_, _, _, _, _, _, track) = allArtistItems(at: indexPath)
                if let track = track {
                    return track.asMPContentItem()
                }
                
            default:
                return nil
            }
        default:
            return nil
        }
        return nil
    }
    
    public func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Swift.Void) {
        guard let section = carPlaySection(from: indexPath) else {
            // TODO: Create an error
            completionHandler(nil)
            return
        }
        
        DispatchQueue.main.async {
            var request : Request?
            switch indexPath.count {
            case 2:
                switch section {
                case .artists:
                    let (artist, _, _, _, _, _, _) = self.allArtistItems(at: indexPath)
                    if let artist = artist {
                        request = RelistenApi.years(byArtist: artist).loadFromCacheThenUpdate()
                    }
                default:
                    break
                }
            case 3:
                switch section {
                case .artists:
                    let (artist, _, year, _, _, _, _) = self.allArtistItems(at: indexPath)
                    if let artist = artist {
                        if let year = year {
                            request = RelistenApi.shows(inYear: year, byArtist: artist).loadFromCacheThenUpdate()
                        }
                    }
                default:
                    break
                }
            case 4:
                switch section {
                case .artists:
                    let (artist, _, _, _, show, _, _) = self.allArtistItems(at: indexPath)
                    if let artist = artist {
                        if let show = show {
                            request = RelistenApi.showWithSources(forShow: show, byArtist: artist).loadFromCacheThenUpdate()
                        }
                    }
                default:
                    break
                }
            default:
                break
            }
            
            if let request = request {
                request.onCompletion { (_) in
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        }
    }

//    public func contentItem(forIdentifier identifier: String, completionHandler: @escaping (MPContentItem?, Error?) -> Swift.Void) {
//
//    }
    
    public func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        return true;
    }
}

// MARK: MPContentItem Conversion Helpers
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

extension Artist {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.artist.\(self.hashValue)"
        }
    }
    
    public func asMPContentItem(withShowCount showCount : Int?) -> MPContentItem {
        // Appending the show count here is a terrible hack, but if I don't do that then CarPlay reuses the Artist cell and the show counts get all mixed up across tabs
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier + "\(showCount ?? 0)")
        contentItem.title = self.name
        if let showCount = showCount {
            var subtitle = "\(showCount) show"
            if showCount > 1 {
                subtitle = subtitle + "s"
            }
            contentItem.subtitle = subtitle
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
        
        if CarPlayController.albumArtEnabled {
            contentItem.artwork = MPMediaItemArtwork(forShow: self.show)
        }

        return contentItem
    }
}

extension Show {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.show.\(self.id)"
        }
    }
    
    public func asMPContentItem() -> MPContentItem {
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
        contentItem.title = self.display_date
        if let venueName = self.venue?.name {
            contentItem.subtitle = "\(venueName)"
        }
        contentItem.isContainer = true
        contentItem.isPlayable = false
        
        if CarPlayController.albumArtEnabled {
            contentItem.artwork = MPMediaItemArtwork(forShow: self)
        }

        return contentItem
    }
}

extension Year {
    public var carPlayIdentifier : String {
        get {
            return "live.relisten.year.\(self.id)"
        }
    }
    
    public func asMPContentItem() -> MPContentItem {
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
        contentItem.title = self.year
        let showString = (show_count > 1) ? "shows" : "show"
        contentItem.subtitle = "\(show_count) \(showString)"
        contentItem.isContainer = true
        contentItem.isPlayable = false
        
        return contentItem
    }
}

extension MPMediaItemArtwork {
    public convenience init(forShow show : Show) {
        self.init(boundsSize: AlbumArtImageCache.imageFormatSmallBounds, requestHandler: { (size) -> UIImage in
            var image : UIImage? = nil
            // I'm pretty unhappy with this. I wish CarPlay provided an escaping closure for returning the UIImage
            let sem = DispatchSemaphore(value: 0)
            AlbumArtImageCache.shared.cache.retrieveImage(for: show.fastImageCacheWrapper(), withFormatName: AlbumArtImageCache.imageFormatSmall, completionBlock: { (_, _, blockImage) in
                image = blockImage
                sem.signal()
            })
            sem.wait()
            return image!
        })
    }
}
