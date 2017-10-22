//
//  MyShowsManager.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import FirebaseCommunity
import Firestore
import SwiftyJSON

public class ShowWithSourcesArtistContainer {
    public let show: ShowWithSources
    public let artist: SlimArtistWithFeatures
    
    public init(show: ShowWithSources, byArtist: SlimArtistWithFeatures) {
        self.show = show
        self.artist = byArtist
    }
    
    public init(json: SwJSON) throws {
        show = try ShowWithSources(json: json["show"])
        artist = try SlimArtistWithFeatures(json: json["artist"])
    }
    
    public var originalJSON: SwJSON {
        get {
            var s = SwJSON()
            s["show"] = show.originalJSON
            s["artist"] = artist.originalJSON
            return s
        }
    }
}

public class MyLibrary {
    public var shows: [ShowWithSourcesArtistContainer]
    public var artistIds: Set<Int>
    
    public var offlineTrackURLs: Set<URL>
    
    public init() {
        shows = []
        artistIds = []
        offlineTrackURLs = []
    }
    
    public init(json: SwJSON) throws {
        shows = try json["shows"].arrayValue.map(ShowWithSourcesArtistContainer.init)
        artistIds = Set(json["artistIds"].arrayValue.map({ $0.intValue }))
        offlineTrackURLs = Set(json["offlineTrackURLs"].arrayValue.map({ $0.url! }))
    }
    
    public func ToJSON() -> SwJSON {
        var s = SwJSON()
        s["shows"] = SwJSON(shows.map({ $0.originalJSON }))
        s["artistIds"] = SwJSON(Array(artistIds))
        s["offlineTrackURLs"] = SwJSON(Array(offlineTrackURLs).map({ $0.absoluteString }))

        return s
    }
}

public class MyLibraryManager {
    static let sharedInstance = MyLibraryManager()
    
    let db = Firestore.firestore()
    
    var user: User? = nil
    var userDoc: DocumentReference? = nil
    var library: MyLibrary
    
    public let favoriteArtistIdsChanged = Event<Set<Int>>()
    
    init() {
        library = MyLibrary()
    }
    
    public func onUserSignedIn(_ user: User) {
        self.user = user
        
        userDoc = db.collection("users")
            .document(user.uid)
        
        loadFromFirestore()
    }
    
    func loadFromFirestore() {
        userDoc?.getDocument(completion: { (docSnapshot, err) in
            if let e = err {
                print(e)
            }
            
            if let d = docSnapshot {
                if !d.exists {
                    self.setupFirstDocument()
                }
                else {
                    self.library = try! MyLibrary(json: SwJSON(d.data()))
                    
                    self.favoriteArtistIdsChanged.raise(data: self.library.artistIds)
                }
            }
        })
    }
    
    func saveToFirestore() {
        if let d = userDoc {
            do {
                let j = library.ToJSON()
                let json = try JSONSerialization.jsonObject(with: try j.rawData()) as! [String: Any]
                
                d.setData(json)
            }
            catch {
                print(error)
            }
        }
    }
    
    func setupFirstDocument() {
        // works because MyLibrary is initalized in the constructor
        saveToFirestore()
    }
}

extension MyLibraryManager {
    public func addShow(show: ShowWithSources, byArtist: SlimArtistWithFeatures) {
        library.shows.append(ShowWithSourcesArtistContainer(show: show, byArtist: byArtist))
        
        saveToFirestore()
    }
    
    public func removeShow(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        if let idx = library.shows.index(where: { $0.show.display_date == show.display_date && $0.artist.id == byArtist.id }) {
            library.shows.remove(at: idx)
            
            saveToFirestore()

            return true
        }
        
        return false
    }
    
    public func favoriteArtist(artist: SlimArtistWithFeatures) {
        library.artistIds.insert(artist.id)
        
        saveToFirestore()
        
        favoriteArtistIdsChanged.raise(data: library.artistIds)
    }
    
    public func removeArtist(artist: SlimArtistWithFeatures) -> Bool {
        if let _ = library.artistIds.remove(artist.id) {
            favoriteArtistIdsChanged.raise(data: library.artistIds)

            saveToFirestore()
            
            return true
        }
        
        return false
    }
}

extension MyLibraryManager {
    public func isShowInLibrary(show: ShowWithSources, byArtist: SlimArtist) -> Bool {
        return library.shows.contains(where: { $0.show.display_date == show.display_date && $0.artist.id == byArtist.id })
    }
    
    public var artistIds: Set<Int>  {
        get {
            return library.artistIds
        }
    }
    
    public var shows: [ShowWithSourcesArtistContainer] {
        get {
            return library.shows
        }
    }
    
    public func isTrackAvailableOffline(track: SourceTrack) -> Bool {
        return library.offlineTrackURLs.contains(track.mp3_url)
    }
}

extension MyLibraryManager {
    public func URLIsAvailableOffline(_ url: URL) {
        library.offlineTrackURLs.insert(url)
        
        saveToFirestore()
    }
}
