//
//  LegacyMapper.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

class LegacyMapper {
    private let api : RelistenLegacyAPI = RelistenLegacyAPI()
    
    public func matchLegacyTrack(artist slug: String, showID: Int, trackID: Int, completion: @escaping (CompleteShowInformation, Error?) -> Void) {
        
    }
    
    private var artistsBySlug : [String : ArtistWithCounts] = [:]
    private func artistFromSlug(_ slug : String, completion : @escaping ((ArtistWithCounts?) -> Void)) {
        if let retval = artistsBySlug[slug] {
            completion(retval)
            return
        }
        
        let res = RelistenApi.artists()
        res.addObserver(owner: self) { (res, _) in
            var foundArtist : ArtistWithCounts? = nil
            if let artists : [ArtistWithCounts] = res.typedContent() {
                for artist in artists {
                    if artist.slug == slug {
                        foundArtist = artist
                        break
                    }
                }
            }
            if let foundArtist = foundArtist {
                self.artistsBySlug[slug] = foundArtist
            }
            completion(foundArtist)
        }
    }
    
    private func loadArtist(withSlug slug : String, completion : @escaping ((SlimArtist?) -> Void)) {
        let res = RelistenApi.artist(withSlug: slug)
        res.addObserver(owner: self) { (res, _) in
            completion(res.typedContent())
        }
    }
}
