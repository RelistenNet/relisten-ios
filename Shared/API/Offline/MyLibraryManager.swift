//
//  MyShowsManager.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Firebase
import FirebaseFirestore
import FirebaseAuth
import SwiftyJSON
import Cache
import Async
import SINQ
import Observable

public class MyLibraryManager {
    static let shared = MyLibraryManager()
    
    let db: Firestore
    
    var user: User? = nil
    var userDoc: DocumentReference? = nil
    var library: MyLibrary = MyLibrary()
    
    public let artistFavorited = Event<ArtistWithCounts>()
    public let artistUnfavorited = Event<ArtistWithCounts>()

    public let showAdded = Event<CompleteShowInformation>()
    public let showRemoved = Event<CompleteShowInformation>()

    public lazy var observeFavoriteArtistIds = Observable(library.artistIds)
    public lazy var observeRecentlyPlayedTracks = Observable(library.recentlyPlayedTracks)
    public lazy var observeMyShows = Observable(library.shows)

    init() {
        RelistenDownloadManager.shared.delegate = self.library
        
        db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        settings.isPersistenceEnabled = true
        
        db.settings = settings
        
        downloadBacklog()
    }
    
    private func downloadBacklog() {
        let i = min(library.downloadBacklog.count, 3)
        for track in library.downloadBacklog[0..<i] {
            RelistenDownloadManager.shared.download(track: track)
        }
    }
    
    public func onUserSignedIn(_ user: User) {
        self.user = user
        
        userDoc = db.collection("users")
            .document(user.uid)
        
        loadFromFirestore()
    }
    
    private func loadFromDocumentSnapshot(_ d: DocumentSnapshot) {
        self.library = try! MyLibrary(json: SwJSON(d.data() as Any))
        
        RelistenDownloadManager.shared.delegate = self.library

        observeRecentlyPlayedTracks.value = library.recentlyPlayedTracks
        observeFavoriteArtistIds.value = library.artistIds
        observeMyShows.value = library.shows
    }
    
    private var addedFirestoreListener = false
    
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
                    self.loadFromDocumentSnapshot(d)
                }
                
                if !self.addedFirestoreListener {
                    self.userDoc?.addSnapshotListener({ (docSnap, err) in
                        if let doc = docSnap, doc.exists {
                            print("found changes from snapshot listener")
                            self.loadFromDocumentSnapshot(doc)
                        }
                    })
                    
                    self.addedFirestoreListener = true
                }
            }
        })
    }
    
    public func deleteFirestoreData() {
        userDoc?.delete()
    }
    
    func saveToFirestore() {
        DispatchQueue.global(qos: .background).async {
            if let d = self.userDoc {
                do {
                    let j = self.library.ToJSON()
                    let json = try JSONSerialization.jsonObject(with: try j.rawData()) as! [String: Any]
                    
                    d.setData(json)
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    func setupFirstDocument() {
        // works because MyLibrary is initalized in the constructor
        saveToFirestore()
    }
}

extension MyLibraryManager {
    public func addShow(show: CompleteShowInformation) {
        library.shows.append(show)
        
        showAdded.raise(show)
        observeMyShows.value = library.shows
        
        saveToFirestore()
    }
    
    public func removeShow(show: CompleteShowInformation) -> Bool {
        if let idx = library.shows.index(where: { $0 == show }) {
            library.shows.remove(at: idx)
            
            showRemoved.raise(show)
            observeMyShows.value = library.shows
            
            saveToFirestore()

            return true
        }
        
        return false
    }
    
    public func favoriteArtist(artist: ArtistWithCounts) {
        if !library.artistIds.contains(artist.id) {
            library.artistIds.insert(artist.id)
            
            saveToFirestore()
            
            artistFavorited.raise(artist)
            observeFavoriteArtistIds.value = library.artistIds
        }
    }
    
    public func removeArtist(artist: ArtistWithCounts) -> Bool {
        if let _ = library.artistIds.remove(artist.id) {
            artistUnfavorited.raise(artist)
            observeFavoriteArtistIds.value = library.artistIds

            saveToFirestore()
            
            return true
        }
        
        return false
    }
    
    public func trackWasPlayed(_ track: Track) {
        if library.trackWasPlayed(track) {
            saveToFirestore()
            
            observeRecentlyPlayedTracks.value = library.recentlyPlayedTracks
        }
    }
}
