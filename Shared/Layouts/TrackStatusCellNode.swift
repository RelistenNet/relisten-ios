//
//  TrackStatusCellNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import NAKPlaybackIndicatorView

import AsyncDisplayKit
import Observable

public class TrackStatusCellNode : ASCellNode {
    public let track: CompleteTrackShowInformation
    public weak var delegate: TrackStatusActionHandler?
    public let explicitTrackNumber: Int?
    public let showArtistInformation: Bool
    
    var disposal = Disposal()
    
    public init(withTrack track: CompleteTrackShowInformation, withHandler handler: TrackStatusActionHandler, usingExplicitTrackNumber: Int? = nil, showingArtistInformation: Bool = false) {
        self.track = track
        self.delegate = handler
        self.explicitTrackNumber = usingExplicitTrackNumber
        self.showArtistInformation = showingArtistInformation
        
        nowPlayingNode = ASDisplayNode(viewBlock: {
            let np = NAKPlaybackIndicatorView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
            np.tintColor = AppColors.primary
            return np
        })
        nowPlayingNode.backgroundColor = UIColor.clear
        
        trackNumberNode = ASTextNode(String(explicitTrackNumber ?? track.track.track.track_position), textStyle: .caption1, color: .darkGray)
        
        titleNode = ASTextNode(track.track.track.title, textStyle: .body)
        titleNode.maximumNumberOfLines = 0
        
        if showingArtistInformation {
            artistInfoNode = ASTextNode(track.artist.name + " • " + track.show.display_date, textStyle: .caption1)
        }
        else {
            artistInfoNode = nil
        }
        
        if let dur = track.track.track.duration, track.artist.features.track_durations {
            durationNode = ASTextNode(dur.humanize(), textStyle: .caption1, color: .darkGray)
        }
        else {
            durationNode = nil
        }
        
        actionButtonNode = ASButtonNode()
        actionButtonNode?.setTitle("···", with: nil, with: nil, for: .normal)
        
        let padding = (44.0 - actionButtonNode!.bounds.size.height)/2.0
        actionButtonNode?.hitTestSlop = UIEdgeInsetsMake(-padding, 0, -padding, 0)
        
        super.init()

        actionButtonNode?.addTarget(self, action: #selector(buttonPressed(_:)), forControlEvents: .touchUpInside)
        automaticallyManagesSubnodes = true
        
        let dl = RelistenDownloadManager.shared
        
        dl.eventTracksDeleted.addHandler { [weak self] (tracks) in
            if let s = self, let _ = tracks.first(where: { $0 == s.track }) {
                s.downloadState = .none
                s.downloadingNode.stopAnimating()
                s.setNeedsLayout()
            }
        }.add(to: &disposal)

        dl.eventTracksQueuedToDownload.addHandler { [weak self] (tracks) in
            if let s = self, let _ = tracks.first(where: { $0 == s.track }) {
                s.downloadState = .queued
                s.downloadingNode.stopAnimating()
                s.setNeedsLayout()
            }
        }.add(to: &disposal)

        dl.eventTrackStartedDownloading.addHandler { [weak self] (track) in
            if let s = self, track == s.track {
                s.downloadState = .downloading
                s.downloadingNode.startAnimating()
                s.setNeedsLayout()
            }
        }.add(to: &disposal)

        dl.eventTrackFinishedDownloading.addHandler { [weak self] (track) in
            if let s = self, track == s.track {
                s.downloadState = .downloaded
                s.downloadingNode.stopAnimating()
                s.setNeedsLayout()
            }
        }.add(to: &disposal)
        
        PlaybackController.sharedInstance.observeCurrentTrack.observe { [weak self] (current, previous) in
            if let s = self {
                let prev = s.trackState
                var newState : TrackState = .notActive
                
                if let track : CompleteTrackShowInformation = current, track == s.track {
                    if track.track.isPlaying {
                        newState = .playing
                    } else if track.track.isActiveTrack {
                        newState = .paused
                    }
                }
                
                if prev != newState {
                    s.trackState = newState
                    DispatchQueue.main.async { s.updateTrackState() }
                    s.setNeedsLayout()
                }
            }
        }.add(to: &disposal)
        
        if track.track.isAvailableOffline {
            downloadState = .downloaded
        }
        else if track.track.isQueuedToDownload {
            downloadState = .queued
        }
        else if track.track.isActivelyDownloading {
            downloadState = .downloading
        }
        else {
            downloadState = .none
        }
        
        if track.track.isActiveTrack {
            if track.track.isPlaying {
                trackState = .playing
            }
            else {
                trackState = .paused
            }
        } else {
            trackState = .notActive
        }
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        delegate?.trackButtonTapped(sender, forTrack: track)
    }
    
    public let nowPlayingNode: ASDisplayNode
    public let trackNumberNode: ASTextNode
    public let titleNode: ASTextNode
    public let artistInfoNode: ASTextNode?
    public let durationNode: ASTextNode?
    public let actionButtonNode: ASButtonNode?
    
    public let offlineNode = OfflineIndicatorNode()
    public let downloadingNode = OfflineDownloadingIndicatorNode()
    
    var trackState = TrackState.notActive
    var downloadState = DownloadState.none
    
    enum TrackState {
        case notActive
        case paused
        case playing
    }
    
    enum DownloadState {
        case none
        case queued
        case downloading
        case downloaded
    }
    
    func updateTrackState() {
        if let nak = nowPlayingNode.view as? NAKPlaybackIndicatorView {
            switch trackState {
            case .paused:
                nak.state = .paused
            case .playing:
                nak.state = .playing
            default:
                nak.state = .stopped
            }
        }
    }
    
    public override func didLoad() {
        super.didLoad()
        
        updateTrackState()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let dlNodeToUse: ASDisplayNode?
        
        switch downloadState {
        case .queued:
            downloadingNode.stopAnimating()
            dlNodeToUse = downloadingNode
        case .downloading:
            downloadingNode.startAnimating()
            dlNodeToUse = downloadingNode
        case .downloaded:
            dlNodeToUse = offlineNode
        default:
            dlNodeToUse = nil
        }
        
        titleNode.style.flexShrink = 1.0
        trackNumberNode.style.minWidth = .init(unit: .points, value: 24)
        
        nowPlayingNode.style.minSize = CGSize(width: 12, height: 12)
        
        let nowPlayingInset = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(0, 0, 0, 12),
            child: nowPlayingNode
        )

        let horiz = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                trackState != .notActive ? nowPlayingInset : trackNumberNode,
                dlNodeToUse,
                titleNode,
                SpacerNode(),
                durationNode,
                actionButtonNode
            )
        )
        horiz.style.alignSelf = .stretch
        horiz.style.flexGrow = 1.0
        
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsetsMake(12, 16, 12, 16),
            child: horiz
        )
        inset.style.alignSelf = .stretch
        
        return inset
    }
}
