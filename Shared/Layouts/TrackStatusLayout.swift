//
//  SourceTrackStatsLayout.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import NAKPlaybackIndicatorView

import ActionKit
import Cache
import SwiftyJSON

public class TrackStatusLayout : InsetLayout<UIView> {
    public init(withTrack track: Track, withHandler handler: TrackStatusActionHandler, usingExplicitTrackNumber: Int? = nil, showingArtistInformation: Bool = false) {
        var stack : [Layout] = []
        
        if (track.playbackState == .paused || track.playbackState == .playing) {
            // 24x16 in total
            let l = InsetLayout(
                insets: UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 12),
                sublayout: SizeLayout<NAKPlaybackIndicatorView>(
                    minWidth: 12,
                    maxWidth: nil,
                    minHeight: 12,
                    maxHeight: nil,
                    alignment: Alignment.center,
                    flexibility: Flexibility.inflexible,
                    viewReuseId: "nowPlaying",
                    sublayout: nil,
                    config: { (p) in
                        switch track.playbackState {
                        case .playing:
                            p.state = .playing
                        case .paused:
                            p.state = .paused
                        case .notActive:
                            p.state = .stopped
                        }
                        p.tintColor = AppColors.primary
                })
            )
            
            stack.append(l)
        }
        // show track number
        else {
            let l = SizeLayout<UILabel>(
                minWidth: 24,
                maxWidth: nil,
                minHeight: 16,
                maxHeight: nil,
                alignment: Alignment.centerLeading,
                flexibility: Flexibility.inflexible,
                viewReuseId: "trackNumber",
                sublayout: nil,
                config: { l in
                    l.text = String(describing: usingExplicitTrackNumber ?? track.track_position)
                    l.font = UIFont.preferredFont(forTextStyle: .caption1)
                    l.textColor = .darkGray
            })
            stack.append(l)
        }
        
        var potentialOfflineLayout: Layout? = nil
        
        switch track.downloadState {
        case .downloaded, .downloading, .queued:
            potentialOfflineLayout = SizeLayout<UIImageView>(
                minWidth: 12,
                maxWidth: nil,
                minHeight: 12,
                maxHeight: nil,
                alignment: Alignment.center,
                flexibility: Flexibility.inflexible,
                viewReuseId: "track",
                sublayout: nil,
                config: { imageV in
                    if track.downloadState == .downloaded {
                        imageV.image = UIImage(named: "download-complete")
                    } else if track.downloadState == .downloading {
                        imageV.image = UIImage(named: "download-active")
                    }
                    
                    if track.downloadState == .downloading {
                        imageV.alpha = 1.0
                        UIView.animate(withDuration: 1.0,
                                       delay: 0,
                                       options: [UIView.AnimationOptions.autoreverse, UIView.AnimationOptions.repeat],
                                       animations: {
                                        imageV.alpha = 0.0
                        },
                                       completion: nil)
                    }
                    else {
                        UIView.animate(withDuration: 0, animations: {
                            imageV.alpha = 1.0
                        })
                    }
            })
        default:
            break
        }
        
        if let p = potentialOfflineLayout, !showingArtistInformation {
            stack.append(InsetLayout(insets: EdgeInsets(top: 0, left: 0, bottom: 0, right: 8), sublayout: p))
        }
        
        let trackTitleLabel = LabelLayout(
            text: track.title,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "trackTitle",
            config: nil
        )
        
        if showingArtistInformation {
            let artistInfoLabel = LabelLayout(
                text: track.showInfo.artist.name + " • " + track.showInfo.show.display_date,
                font: UIFont.preferredFont(forTextStyle: .caption1),
                numberOfLines: 0,
                alignment: .fillLeading,
                flexibility: .flexible,
                viewReuseId: "artistInfo",
                config: nil
            )
            
            var subs: [Layout] = [
                trackTitleLabel
            ]
            
            if let p = potentialOfflineLayout {
                subs.append(StackLayout(
                    axis: .horizontal,
                    spacing: 4,
                    sublayouts: [
                        p,
                        artistInfoLabel
                    ]
                ))
            }
            else {
                subs.append(artistInfoLabel)
            }
            
            stack.append(StackLayout(
                axis: .vertical,
                spacing: 4,
                sublayouts: subs
            ))
        }
        else {
            stack.append(trackTitleLabel)
        }
        
        if let dur = track.duration, track.showInfo.artist.features.track_durations {
            let label = LabelLayout(
                text: dur.humanize(),
                font: UIFont.preferredFont(forTextStyle: .caption1),
                numberOfLines: 1,
                alignment: .centerLeading,
                flexibility: .inflexible,
                viewReuseId: "trackDuration",
                config: { (l) in
                    l.textColor = .darkGray
            })
            
            stack.append(InsetLayout(insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), sublayout: label))
        }
        
        let actionButton = ButtonLayout(
            type: ButtonLayoutType.system,
            title: "···",
            image: .defaultImage,
            font: nil,
            contentEdgeInsets: nil,
            alignment: .center,
            flexibility: .inflexible,
            viewReuseId: "moreButton",
            config: { v in
                v.addControlEvent(.touchUpInside, {
                    handler.trackButtonTapped(v, forTrack: track)
                })
            }
        )
        
        stack.append(actionButton)
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            viewReuseId: "trackStatusLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 0,
                sublayouts: stack
            )
        )
    }
}
