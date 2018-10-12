//
//  TrackStatusNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/11/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public protocol TrackStatusActionHandler : class {
    func trackButtonTapped(_ button: UIButton, forTrack track: Track)
}

public class TrackStatusNode: ASCellNode {
    let track: Track
    let actionHandler: TrackStatusActionHandler
    let trackNumber: Int?
    
    public init(withTrack track: Track, withHandler handler: TrackStatusActionHandler, usingExplicitTrackNumber: Int? = nil, showingArtistInformation: Bool = false) {
        self.track = track
        self.actionHandler = handler
        self.trackNumber = usingExplicitTrackNumber
        
        if (track.playbackState == .paused || track.playbackState == .playing) {
            playbackIndicatorNode = PlaybackIndicatorNode()
            switch track.playbackState {
            case .playing:
                playbackIndicatorNode?.state = .playing
            case .paused:
                playbackIndicatorNode?.state = .paused
            case .notActive:
                playbackIndicatorNode?.state = .stopped
            }
            playbackIndicatorNode?.view.tintColor = AppColors.primary
            trackNumberNode = nil
        } else {
            playbackIndicatorNode = nil
            let trackNumber = String(describing: usingExplicitTrackNumber ?? track.track_position)
            trackNumberNode = ASTextNode(trackNumber, textStyle: .caption1, color: .darkGray)
        }
        
        switch track.downloadState {
        case .downloaded, .downloading, .queued:
            let imageNode = ASImageNode()
            imageNode.style.maxWidth = .init(unit: .points, value: 12)
            imageNode.style.maxHeight = .init(unit: .points, value: 12)
            imageNode.style.preferredSize = CGSize(width: imageNode.style.maxWidth.value, height: imageNode.style.maxHeight.value)
            imageNode.style.flexShrink = 1.0
            
            if track.downloadState == .downloaded {
                imageNode.image = UIImage(named: "download-complete")
            } else if track.downloadState == .downloading {
                imageNode.image = UIImage(named: "download-active")
            }
            
            self.downloadImageNode = imageNode
        default:
            self.downloadImageNode = nil
            break
        }
        
        trackTitleNode = ASTextNode(track.title, textStyle: .body)
        
        if showingArtistInformation {
            artistInfoNode = ASTextNode(track.showInfo.artist.name + " • " + track.showInfo.show.display_date, textStyle: .caption1)
        } else {
            artistInfoNode = nil
        }
        
        if let duration = track.duration, track.showInfo.artist.features.track_durations {
            durationNode = ASTextNode(duration.humanize(), textStyle: .caption1)
        } else {
            durationNode = nil
        }
        
        actionNode = ASButtonNode()
        actionNode.setTitle("···", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.primary, for: .normal)
        
        super.init()
        
        actionNode.addTarget(self, action: #selector(actionButtonPressed(_:)), forControlEvents: .touchUpInside)
        
        self.automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    @objc func actionButtonPressed(_ sender: UIButton) {
        actionHandler.trackButtonTapped(sender, forTrack: self.track)
    }
    
    let playbackIndicatorNode: PlaybackIndicatorNode?
    let trackNumberNode: ASTextNode?
    let downloadImageNode: ASImageNode?
    let trackTitleNode: ASTextNode
    let artistInfoNode: ASTextNode?
    let durationNode: ASTextNode?
    let actionNode: ASButtonNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let trackInfoStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                playbackIndicatorNode,
                trackNumberNode,
                downloadImageNode,
                trackTitleNode,
                SpacerNode(),
                durationNode,
                actionNode
            )
        )
        trackInfoStack.style.alignSelf = .stretch
        
        let fullTrackStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .start,
            children: ArrayNoNils(
                trackInfoStack,
                artistInfoNode
            )
        )
        fullTrackStack.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: fullTrackStack
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}
