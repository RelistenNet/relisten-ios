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
    
    public lazy var observeFavoriteArtistIds = Observable(library.artistIds)
    public lazy var observeRecentlyPlayedShows = Observable(library.recentlyPlayed)

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

        observeRecentlyPlayedShows.value = library.recentlyPlayed
        observeFavoriteArtistIds.value = library.artistIds
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
    public func addShow(show: CompleteShowInformation) {
        library.shows.append(show)
        
        saveToFirestore()
    }
    
    public func removeShow(show: CompleteShowInformation) -> Bool {
        if let idx = library.shows.index(where: { $0 == show }) {
            library.shows.remove(at: idx)
            
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
    
    public func trackWasPlayed(_ track: CompleteTrackShowInformation) {
        if library.trackWasPlayed(track) {
            saveToFirestore()
            
            observeRecentlyPlayedShows.value = library.recentlyPlayed
        }
    }
}

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
