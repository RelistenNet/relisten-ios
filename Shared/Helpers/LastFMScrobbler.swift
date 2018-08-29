//
//  LastFMScrobbler.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/28/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import LastFm
import Observable

public struct LastFMError : Error {
    let reasonString : String
}

public class LastFMScrobbler {
    public static var shared = LastFMScrobbler()
    
    private static let APIKey = "f2b89dbc431a938a385203bb218e5310"
    private static let APISecret = "5c1ace2f9e7cdbb4c0b2fbbcc9ddb426"
    
    private static let usernameDefaultKey = "lastfm_username_key"
    private static let sessionDefaultKey = "lastfm_session_key"
    
    public var username : String? {
        didSet {
            self.observeUsername.value = username
            self.lastFM.username = username
            
            if username != nil {
                UserDefaults.standard.setValue(username, forKey: LastFMScrobbler.usernameDefaultKey)
            } else {
                UserDefaults.standard.removeObject(forKey: LastFMScrobbler.usernameDefaultKey)
            }
        }
    }
    public let observeUsername = Observable<String?>(nil)
    
    private var sessionKey : String?{
        didSet {
            self.lastFM.session = sessionKey
            
            if sessionKey != nil {
                UserDefaults.standard.setValue(sessionKey, forKey: LastFMScrobbler.sessionDefaultKey)
            } else {
                UserDefaults.standard.removeObject(forKey: LastFMScrobbler.sessionDefaultKey)
            }
        }
    }
    
    public var isLoggedIn : Bool {
        return sessionKey != nil
    }
    public let observeLoggedIn = Observable<Bool>(false)
    
    private let lastFM : LastFm = LastFm.sharedInstance()!
    private var disposal = Disposal()
    
    public init() {
        username = UserDefaults.standard.string(forKey: LastFMScrobbler.usernameDefaultKey)
        sessionKey = UserDefaults.standard.string(forKey: LastFMScrobbler.sessionDefaultKey)
        
        lastFM.apiKey = LastFMScrobbler.APIKey
        lastFM.apiSecret = LastFMScrobbler.APISecret
        lastFM.username = username
        lastFM.session = sessionKey
        
        PlaybackController.sharedInstance.eventTrackPlaybackStarted.addHandler({ [weak self] t in
            guard let s = self else { return }
            guard let track = t else { return }
            
            s.trackStartedPlaying(track)
        }).add(to: &disposal)
        
        PlaybackController.sharedInstance.eventTrackWasPlayed.addHandler({ [weak self] track in
            guard let s = self else { return }
            
            s.scrobbleTrack(track)
        }).add(to: &disposal)
    }
    
    public func login(username: String, password: String, completion: @escaping (Error?) -> Void) {
        LogDebug("Logging in to Last.fm as user \(username)")
        lastFM.getSessionForUser(username, password: password, successHandler: { (r) in
            guard let result = r else {
                LogDebug("Got a successful callback for login, but didn't get any response data")
                completion(LastFMError(reasonString: "Got a successful callback for login, but didn't get any response data"))
                return
            }
            
            if let resultSessionKey = result["key"] as! String? {
                self.username = username
                self.sessionKey = resultSessionKey
                completion(nil)
            } else {
                LogDebug("Got a successful callback for login, but didn't get a session key. Sorry buddy- we're calling this one a failure.")
                completion(LastFMError(reasonString: "Got a successful callback for login, but didn't get a session key."))
            }
        }, failureHandler: { (e) in
            let error = e ?? LastFMError(reasonString: "Login failure with no error")
            LogDebug("Failed to log in to last.fm as user \(username): \(error)")
            completion(error)
        })
    }
    
    public func trackStartedPlaying(_ track: Track) {
        guard self.isLoggedIn else { return }
        
        LogDebug("Sending now playing to Last.fm: [\(track.title) | \(track.showInfo.artist.name) | \(track.albumName)]")
        lastFM.sendNowPlayingTrack(track.title, byArtist: track.showInfo.artist.name, onAlbum: track.albumName, withDuration: track.duration ?? 0.0, successHandler: nil, failureHandler: nil)
    }
    
    public func scrobbleTrack(_ track : Track) {
        guard self.isLoggedIn else { return }
        
        LogDebug("Sending scrobble to Last.fm: [\(track.title) | \(track.showInfo.artist.name) | \(track.albumName)]")
        lastFM.sendScrobbledTrack(track.title, byArtist: track.showInfo.artist.name, onAlbum: track.albumName, withDuration: track.duration ?? 0.0, atTimestamp: Date().timeIntervalSince1970, successHandler: nil, failureHandler: nil)
    }
}

extension Track {
    var albumName : String {
        get {
            if let venueName = self.showInfo.show.venue?.name {
                return "\(self.showInfo.show.display_date) - \(venueName)"
            } else {
                return self.showInfo.show.display_date
            }
        }
    }
}
