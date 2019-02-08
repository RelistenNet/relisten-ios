//
//  TestDataGenerator.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 12/21/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public class TestDataGenerator {
    public static let shared = TestDataGenerator()
    
    public func generateRecentlyPlayed(_ numTracks : Int = 1000, completion: @escaping (Error?) -> Void) {
        let completionGroup = DispatchGroup()
        var error : Error? = nil
        
        let numArtists = max(1, numTracks / 100)
        LogWarn("Generating \(numTracks) plays across \(numArtists) artists.")
        
        completionGroup.enter()
        DispatchQueue.main.async {
            RelistenApi.artists().getLatestDataOrFetchIfNeeded { (latestData, blockError) in
                if blockError != nil {
                    error = blockError
                } else if let artists : [ArtistWithCounts] = latestData?.typedContent() {
                    for i in (0..<numArtists) {
                        if let artist = artists.randomElement() {
                            completionGroup.enter()
                            var artistTrackCount = Int(numTracks / numArtists)
                            if i == numArtists - 1 {
                                artistTrackCount = numTracks % numArtists
                            }
                            self.generateRecentlyPlayed(forArtist: artist, numTracks: artistTrackCount, completion: { (completionError) in
                                if completionError != nil, error == nil {
                                    error = completionError
                                }
                                completionGroup.leave()
                            })
                        }
                    }
                }
                
                completionGroup.leave()
            }
        }
        
        completionGroup.notify(queue: DispatchQueue.global()) {
            completion(error)
        }
    }
    
    public func generateRecentlyPlayed(forArtist artist: ArtistWithCounts, numTracks : Int = 100, completion: @escaping (Error?) -> Void) {
        var tracksRemaining = numTracks
        
        LogWarn("Generating \(numTracks) plays for artist \(artist.name)")
        
        DispatchQueue.main.async {
            RelistenApi.randomShow(byArtist: artist).getLatestDataOrFetchIfNeeded { (latestData, blockError) in
                DispatchQueue.global().async {
                    if blockError != nil {
                        completion(blockError)
                    } else if let show : ShowWithSources = latestData?.typedContent() {
                        let unknownString = "unknown"
                        LogWarn("[\(artist.name)] Generating track plays across \(show.sources.count) sources for the show \(show.display_date) - \(show.venue?.name ?? unknownString)")
                        for source in show.sources {
                            if tracksRemaining > 0 {
                                let showInfo = CompleteShowInformation(source: source, show: show, artist: artist)
                                for sourceTrack in source.tracksFlattened {
                                    if tracksRemaining > 0 {
                                        let track = Track(sourceTrack: sourceTrack, showInfo: showInfo)
                                        LogWarn("[\(artist.name)] Generating track play for \(sourceTrack.title)")
                                        let _ = MyLibrary.shared.trackWasPlayed(track, pastHalfway: false)
                                        let _ = MyLibrary.shared.trackWasPlayed(track, pastHalfway: true)
                                        tracksRemaining -= 1
                                    } else {
                                        break
                                    }
                                }
                            } else {
                                break
                            }
                        }
                        
                        if tracksRemaining > 0 {
                            self.generateRecentlyPlayed(forArtist: artist, numTracks: tracksRemaining, completion: completion)
                        } else {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
}
