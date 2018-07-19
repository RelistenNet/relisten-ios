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

public class CarPlayController : NSObject, MPPlayableContentDelegate, MPPlayableContentDataSource, ResourceObserver {
    static let shared = CarPlayController()
    var disposal = Disposal()
    
    private var recentlyPlayedShows: [CompleteShowInformation] = []
    private var offlineShows: [OfflineSourceMetadata] = []
    private var favoriteShowsByArtist: [Artist : [CompleteShowInformation]] = [:]
    
    private var favoriteArtistIds : [Int] = [] {
        didSet {
            _sortedArtists = self.sortedArtists(self.allArtists)
        }
    }
    
    private var _sortedArtists : [ArtistWithCounts] = []
    private var allArtists: [ArtistWithCounts] {
        get {
            return _sortedArtists
        }
        
        set {
            let artists = sortedArtists(newValue)
            if !(artists == _sortedArtists) {
                _sortedArtists = artists
            }
        }
    }
    
    // MARK: Setup
    
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
        
        MyLibraryManager.shared.observeFavoriteArtistIds.observe({ [weak self] artistIds, _ in
            self?.reloadFavoriteArtistIds(artistIds: Array(artistIds))
        }).add(to: &disposal)
        
        MyLibraryManager.shared.observeMyShows.observe({ [weak self] shows, _ in
            self?.reloadFavorites(shows: MyLibraryManager.shared.library.shows)
        }).add(to: &disposal)
        
        loadArtists()
    }
    
    deinit {
        RelistenApi.artists().removeObservers(ownedBy: self)
    }
    
    private func loadArtists() {
        let resource = RelistenApi.artists()
        resource.addObserver(self)
        resource.loadFromCacheThenUpdate()
    }
    
    private func sortedArtists(_ artists : [ArtistWithCounts]) -> [ArtistWithCounts] {
        var favoriteArtists : [ArtistWithCounts] = []
        var remainingArtists : [ArtistWithCounts] = []
        for artist : ArtistWithCounts in artists {
            if self.favoriteArtistIds.contains(artist.id) {
                favoriteArtists.append(artist)
            } else {
                remainingArtists.append(artist)
            }
        }
        return favoriteArtists + remainingArtists
    }
    
    private func sortArtists() {
        let sortedArtists = self.sortedArtists(self.allArtists)
        if !(sortedArtists != self.allArtists) {
            self.allArtists = sortedArtists
        }
    }
    
    // MARK: Favorite Accessors
    private var favoriteArtistsSorted : [Artist] {
        get {
            return favoriteShowsByArtist.keys.sorted(by: { (lhs, rhs) -> Bool in return lhs.name > rhs.name })
        }
    }
    
    private func favoriteArtist(at index: Int) -> Artist? {
        let sortedArtists = favoriteArtistsSorted
        if index >= 0, index < favoriteArtistsSorted.count {
            return sortedArtists[index]
        }
        return nil
    }
    
    private func favoriteShowsForArtist(at index: Int) -> [CompleteShowInformation]? {
        if let artist = favoriteArtist(at: index) {
            return favoriteShowsByArtist[artist]
        }
        return nil
    }
    
    // MARK: Reloading Data
    private func reloadRecentTracks(tracks: [Track]) {
        let recentShows : [CompleteShowInformation] = tracks.map { (track : Track) -> CompleteShowInformation in
            return track.showInfo
        }
        if !(recentShows == recentlyPlayedShows) {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.recentlyPlayedShows = recentShows
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
    
    private func reloadFavoriteArtistIds(artistIds: [Int]) {
        DispatchQueue.main.async {
            MPPlayableContentManager.shared().beginUpdates()
            self.favoriteArtistIds = artistIds
            MPPlayableContentManager.shared().endUpdates()
            MPPlayableContentManager.shared().reloadData()
        }
    }
    
    private func reloadFavorites(shows: [CompleteShowInformation]) {
        var showsByArtist : [Artist : [CompleteShowInformation]] = [:]
        shows.forEach { (show) in
            var artistShows = showsByArtist[show.artist]
            if artistShows == nil {
                artistShows = []
            }
            artistShows?.append(show)
            showsByArtist[show.artist] = artistShows
        }
        if !(showsByArtist == favoriteShowsByArtist) {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.favoriteShowsByArtist = showsByArtist
                MPPlayableContentManager.shared().endUpdates()
                MPPlayableContentManager.shared().reloadData()
            }
        }
    }
    
    public func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        if let resourceData : [ArtistWithCounts] = resource.latestData?.typedContent() {
            DispatchQueue.main.async {
                MPPlayableContentManager.shared().beginUpdates()
                self.allArtists = resourceData
                MPPlayableContentManager.shared().endUpdates()
                MPPlayableContentManager.shared().reloadData()
            }
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
            (_, track) = offlineItems(at: indexPath)
            
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
            if let viewController = AppDelegate.shared.rootNavigationController.topViewController {
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
                showInfo = recentlyPlayedShows[indexPath[1]]
            }
            if indexPath.count > 2 {
                if let showInfo = showInfo {
                    let sourceTrack = showInfo.source.tracksFlattened[indexPath[2]]
                    track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
                }
            }
        }
        
        return (showInfo, track)
    }
    
    private func offlineItems(at indexPath: IndexPath) -> (OfflineSourceMetadata?, Track?) {
        var offlineMetadata : OfflineSourceMetadata?
        var track : Track?
        if carPlaySection(from: indexPath) == .availableOffline {
            if indexPath.count > 1 {
                offlineMetadata = offlineShows[indexPath[1]]
            }
            if indexPath.count > 2 {
                if let offlineMetadata = offlineMetadata {
                    let sourceTrack = offlineMetadata.source.tracksFlattened[indexPath[2]]
                    track = Track(sourceTrack: sourceTrack, showInfo: offlineMetadata.completeShowInformation)
                }
            }
        }
        
        return (offlineMetadata, track)
    }
    
    private func favoriteItems(at indexPath: IndexPath) -> (Artist?, showCount : Int?, CompleteShowInformation?, Track?) {
        var artist : Artist?
        var showCount : Int?
        var show : CompleteShowInformation?
        var track : Track?
        if carPlaySection(from: indexPath) == .favorite {
            if indexPath.count > 1 {
                artist = favoriteArtist(at: indexPath[1])
                if let artist = artist {
                    if let shows = favoriteShowsByArtist[artist] {
                        showCount = shows.count
                    }
                }
            }
            if indexPath.count > 2 {
                if let artist = artist {
                    if let shows = favoriteShowsByArtist[artist] {
                        show = shows[indexPath[2]]
                    }
                }
            }
            if indexPath.count > 3 {
                if let show = show {
                    let sourceTrack = show.source.tracksFlattened[indexPath[3]]
                    track = Track(sourceTrack: sourceTrack, showInfo: show)
                }
            }
        }
        return (artist, showCount, show, track)
    }
    
    private func allArtistItems(at indexPath: IndexPath) -> (ArtistWithCounts?, yearCount: Int?, Year?, showCount: Int?, Show?, SourceFull?, Track?) {
        var artist : ArtistWithCounts?
        var yearCount : Int?
        var years : [Year]?
        var year : Year?
        var yearWithShows : YearWithShows?
        var showCount : Int?
        var show : Show?
        var showWithSources : ShowWithSources?
        var source : SourceFull?
        var track : Track?
        let block = {
            if self.carPlaySection(from: indexPath) == .artists {
                if indexPath.count > 1 {
                    artist = self.allArtists[indexPath[1]]
                    if let artist = artist {
                        showCount = artist.show_count
                        
                        years = RelistenApi.years(byArtist: artist).latestData?.typedContent()
                        if let y = years {
                            years = sortedYears(from: y, for: artist)
                            yearCount = y.count
                        }
                    }
                }
                if let artist = artist {
                    if indexPath.count > 2 {
                        if let years = years {
                            year = years[indexPath[2]]
                            
                            if let year = year {
                                yearWithShows = RelistenApi.shows(inYear: year, byArtist: artist).latestData?.typedContent()
                                if let yearWithShows = yearWithShows {
                                    showCount = yearWithShows.shows.count
                                }
                            }
                        }
                    }
                    if indexPath.count > 3 {
                        if let yearWithShows = yearWithShows {
                            show = yearWithShows.shows[indexPath[3]]
                            if let show = show {
                                showWithSources = RelistenApi.showWithSources(forShow: show, byArtist: artist).latestData?.typedContent()
                                if let showWithSources = showWithSources {
                                    source = showWithSources.sources.first
                                }
                            }
                        }
                    }
                    if indexPath.count > 4 {
                        if let show = show {
                            if let source = source {
                                let sourceTrack = source.tracksFlattened[indexPath[4]]
                                let completeShowInfo = CompleteShowInformation(source: source, show: show, artist: artist)
                                track = Track(sourceTrack: sourceTrack, showInfo: completeShowInfo)
                            }
                        }
                    }
                }
            }
        }
        if !(Thread.isMainThread) {
            DispatchQueue.main.sync(execute: block)
        } else {
            block()
        }
        return (artist, yearCount, year, showCount, show, source, track)
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
            switch section {
            case .recentlyPlayed:
                // Recent->Shows
                return recentlyPlayedShows.count
                
            case .availableOffline:
                // Offline->Shows
                return offlineShows.count
                
            case .favorite:
                // Favorites->Artists
                return favoriteShowsByArtist.count
                
            case .artists:
                // Artists->Artists
                return allArtists.count
                
            case .count:
                return 0
            }
        case 2:
            switch section {
            case .recentlyPlayed:
                // Recent->Show->Tracks
                let (show, _) = recentShowItems(at: indexPath)
                if let show = show {
                    return show.source.tracksFlattened.count
                }
                
            case .availableOffline:
                // Offline->Show->Tracks
                let (offlineMetadata, _) = offlineItems(at: indexPath)
                if let offlineMetadata = offlineMetadata {
                    return offlineMetadata.source.tracksFlattened.count
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
                let (_, _, _, _, _, source, _) = allArtistItems(at: indexPath)
                if let source = source {
                    return source.tracksFlattened.count
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
                // Offline->Shows
                let (offlineMetadata, _) = offlineItems(at: indexPath)
                if let offlineMetadata = offlineMetadata {
                    return offlineMetadata.asMPContentItem()
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
                // Offline->Show->Tracks
                let (_, track) = offlineItems(at: indexPath)
                if let track = track {
                    return track.asMPContentItem()
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
                    let (artist, _, _, _, showInfo, _, _) = self.allArtistItems(at: indexPath)
                    if let artist = artist {
                        if let showInfo = showInfo {
                            request = RelistenApi.showWithSources(forShow: showInfo, byArtist: artist).loadFromCacheThenUpdate()
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
        let contentItem = MPContentItem(identifier: self.carPlayIdentifier)
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
