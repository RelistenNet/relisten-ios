//
//  TrackStatusCellNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import NAKPlaybackIndicatorView
import DownloadButton

import AsyncDisplayKit
import Observable

import RealmSwift

public protocol TrackStatusActionHandler : class {
    func trackButtonTapped(_ button: UIButton, forTrack track: Track)
}

public class TrackStatusCellNode : ASCellNode {
    public let track: Track
    public weak var delegate: TrackStatusActionHandler?
    public let explicitTrackNumber: Int?
    public let showArtistInformation: Bool
    
    var disposal = Disposal()
    
    var offlineTrackQuery: Results<OfflineTrack>!
    var listenedTrackQuery: Results<RecentlyPlayedTrack>!
    
    public init(withTrack track: Track, withHandler handler: TrackStatusActionHandler, usingExplicitTrackNumber: Int? = nil, showingArtistInformation: Bool = false) {
        self.track = track
        self.delegate = handler
        self.explicitTrackNumber = usingExplicitTrackNumber
        self.showArtistInformation = showingArtistInformation
        
        nowPlayingNode = PlaybackIndicatorNode()
        nowPlayingNode.tintColor = AppColors.primary
        nowPlayingNode.backgroundColor = UIColor.clear
        
        if let _ = MyLibrary.shared.recent.tracks.filter("track_uuid == %@ AND past_halfway == true", self.track.uuid.uuidString).first {
            hasListened = true
        }
        trackNumberNode = ASTextNode(String(explicitTrackNumber ?? track.track_position), textStyle: .caption1, color: hasListened ?  AppColors.primary : .darkGray)
        
        titleNode = ASTextNode(track.title, textStyle: .body)
        titleNode.maximumNumberOfLines = 0
        
        if showingArtistInformation {
            artistInfoNode = ASTextNode(track.showInfo.artist.name + " • " + track.showInfo.show.display_date, textStyle: .caption1)
        }
        else {
            artistInfoNode = nil
        }
        
        if let dur = track.duration, track.showInfo.artist.features.track_durations {
            durationNode = ASTextNode(dur.humanize(), textStyle: .caption1, color: .darkGray)
        }
        else {
            durationNode = nil
        }
        
        actionButtonNode = ASButtonNode()
        actionButtonNode?.setImage(UIImage(named: "dots"), for: .normal)
        
        let padding = (44.0 - actionButtonNode!.bounds.size.height)/2.0
        actionButtonNode?.hitTestSlop = UIEdgeInsets(top: -padding, left: 0, bottom: -padding, right: 0)
        
        super.init()

        actionButtonNode?.addTarget(self, action: #selector(buttonPressed(_:)), forControlEvents: .touchUpInside)
        automaticallyManagesSubnodes = true
        
        DispatchQueue.main.async {
            self.offlineTrackQuery = MyLibrary.shared.offline.tracks.filter("track_uuid == %@", self.track.uuid.uuidString)
            self.offlineTrackQuery.observeWithValue { [weak self] trackResults, changes in
                guard let s = self else { return }
                
                if let track = trackResults.first, track.state != .unknown, track.state != .deleting {
                    switch track.state {
                    case .downloaded:
                        s.downloadState = .downloaded
                        
                    case .downloadQueued:
                        s.downloadState = .queued
                        
                    case .downloading:
                        s.downloadState = .downloading
                        
                        DownloadManager.shared.observeProgressForTrack(s.track, observer: { [weak self] progress in
                            if let s = self {
                                s.downloadProgressNode.updateProgress(progress)
                            }
                        })
                        
                    default:
                        // this doesn't happen here because of the if
                        break
                    }
                    
                    s.setNeedsLayout()
                }
                else {
                    s.downloadState = .none
                    s.setNeedsLayout()
                }
            }.dispose(to: &self.disposal)
            
            
            self.listenedTrackQuery = MyLibrary.shared.recent.tracks.filter("track_uuid == %@", self.track.uuid.uuidString)
            self.listenedTrackQuery.observeWithValue { [weak self] trackResults, changes in
                guard let s = self,
                      let track = trackResults.first
                    else { return }
                
                s.hasListened = track.past_halfway
                
            }.dispose(to: &self.disposal)
        }
        
        RelistenApp.sharedApp.playbackController.observeCurrentTrack.observe { [weak self] (current, previous) in
            if let s = self {
                let prev = s.trackState
                var newState : Track.PlaybackState = .notActive
                
                if let track : Track = current, track == s.track {
                    newState = track.playbackState
                }
                
                if prev != newState {
                    s.trackState = newState
                    DispatchQueue.main.async { s.updateTrackState() }
                    s.setNeedsLayout()
                }
            }
        }.add(to: &disposal)
    
        downloadState = track.downloadState
        trackState = track.playbackState
        downloadProgressNode.delegate = self
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        delegate?.trackButtonTapped(sender, forTrack: track)
    }
    
    public let nowPlayingNode: PlaybackIndicatorNode
    public var trackNumberNode: ASTextNode!
    public let titleNode: ASTextNode
    public let artistInfoNode: ASTextNode?
    public let durationNode: ASTextNode?
    public let actionButtonNode: ASButtonNode?
    
    public let offlineNode = OfflineIndicatorNode()
    public let downloadProgressNode = DownloadProgressNode()
    
    var trackState : Track.PlaybackState = .notActive
    var downloadState : Track.DownloadState = .none {
        didSet {
            downloadProgressNode.state = downloadState
        }
    }
    var hasListened : Bool = false {
        didSet {
            trackNumberNode = ASTextNode(String(explicitTrackNumber ?? track.track_position), textStyle: .caption1, color: hasListened ? AppColors.primary : .darkGray)
            self.setNeedsDisplay()
        }
    }

    func updateTrackState() {
        switch trackState {
        case .paused:
            nowPlayingNode.state = .paused
        case .playing:
            nowPlayingNode.state = .playing
        default:
            nowPlayingNode.state = .stopped
        }
    }
    
    public override func didLoad() {
        super.didLoad()
        
        updateTrackState()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let downloadProgressToShow : DownloadProgressNode? = downloadState == .none ? nil : downloadProgressNode

        titleNode.style.flexShrink = 1.0
        trackNumberNode.style.minWidth = .init(unit: .points, value: 24)
        
        nowPlayingNode.style.minSize = CGSize(width: 12, height: 12)
        
        let nowPlayingInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12),
            child: nowPlayingNode
        )

        let horiz = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                trackState != .notActive ? nowPlayingInset : trackNumberNode,
                downloadProgressToShow,
                titleNode,
                SpacerNode(),
                durationNode,
                actionButtonNode
            )
        )
        horiz.style.alignSelf = .stretch
        horiz.style.flexGrow = 1.0
        
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: horiz
        )
        inset.style.alignSelf = .stretch
        
        return inset
    }
}

extension TrackStatusCellNode : DownloadProgressDelegate {
    public func downloadButtonTapped() {
        switch downloadProgressNode.state {
        case .none:
            let _ = DownloadManager.shared.download(track: track)
        case .queued, .downloading:
            DownloadManager.shared.delete(track: track)
        case .downloaded:
            break
        }
    }
}
