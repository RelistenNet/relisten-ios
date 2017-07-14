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

public class TrackStatusLayout : InsetLayout<UIView> {
    public init(forTrack track: TrackStatus, inSource source: SourceFull, byArtist artist: SlimArtistWithFeatures) {
        var stack : [Layout] = []
        
        if track.isActiveTrack {
            let l = SizeLayout<NAKPlaybackIndicatorView>(
                minWidth: 24,
                maxWidth: nil,
                minHeight: nil,
                maxHeight: nil,
                alignment: Alignment.center,
                flexibility: Flexibility.inflexible,
                viewReuseId: "nowPlaying",
                sublayout: nil,
                config: { (p) in
                    p.state = track.isPlaying ? .playing : .paused
            })
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
                config: { (l) in
                    l.text = String(describing: track.track.track_position)
                    l.font = UIFont.preferredFont(forTextStyle: .caption1)
                    l.textColor = .darkGray
            })
            stack.append(l)
        }
        
        stack.append(LabelLayout(
            text: track.track.title,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "trackTitle",
            config: nil
        ))
        
        if let dur = track.track.duration, artist.features.track_durations {
            stack.append(LabelLayout(
                text: dur.humanize(),
                font: UIFont.preferredFont(forTextStyle: .caption1),
                numberOfLines: 1,
                alignment: .centerLeading,
                flexibility: .inflexible,
                viewReuseId: "trackDuration",
                config: { (l) in
                    l.textColor = .darkGray
            }))
        }
        
        stack.append(ButtonLayout(
            type: ButtonLayoutType.system,
            title: "···",
            image: .defaultImage,
            font: nil,
            contentEdgeInsets: nil,
            alignment: .center,
            flexibility: .inflexible,
            viewReuseId: "moreButton",
            config: nil
        ))
        
        super.init(
            insets: EdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            viewReuseId: "sourceDetailsLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 8,
                sublayouts: stack
            )
        )
    }
}

