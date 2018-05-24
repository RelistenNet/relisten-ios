//
//  MyShowsManager.swift
//  Relisten
//
//  Created by Alec Gorge on 10/21/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Firebase
import SwiftyJSON
import Cache
import Async
import SINQ

public class MyLibraryManager {
    static let shared = MyLibraryManager()
    
    let db = Firestore.firestore()
    
    var user: User? = nil
    var userDoc: DocumentReference? = nil
    var library: MyLibrary
    
    public let favoriteArtistIdsChanged = Event<Set<Int>>()
    
    init() {
        library = MyLibrary()
        
        RelistenDownloadManager.shared.delegate = self.library
        
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
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

        self.favoriteArtistIdsChanged.raise(data: self.library.artistIds)
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

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
