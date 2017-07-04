//
//  TrackStatus.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

public class TrackStatus {
    public let track: SourceTrack
    
    public var isPlaying = false
    public var isActiveTrack = false
    
    public init(forTrack: SourceTrack) {
        track = forTrack
    }
}
