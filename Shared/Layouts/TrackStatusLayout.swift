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

public protocol TrackStatusActionHandler {
    func trackButtonTapped(_ button: UIButton, forTrack track: CompleteTrackShowInformation)
}

public protocol ICompleteShowInformation {
    var source: SourceFull { get }
    var show: ShowWithSources { get }
    var artist: SlimArtistWithFeatures { get }
}

public struct CompleteShowInformation : ICompleteShowInformation {
    public let source: SourceFull
    public let show: ShowWithSources
    public let artist: SlimArtistWithFeatures
}

public struct CompleteTrackShowInformation : ICompleteShowInformation {
    public let track: TrackStatus
    public let source: SourceFull
    public let show: ShowWithSources
    public let artist: SlimArtistWithFeatures
}

public class TrackStatusLayout : InsetLayout<UIView> {
    public init(withTrack track: CompleteTrackShowInformation, withHandler handler: TrackStatusActionHandler) {
        var stack : [Layout] = []
        
        if track.track.isActiveTrack {
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
                    p.state = track.track.isPlaying ? .playing : .paused
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
                    l.text = String(describing: track.track.track.track_position)
                    l.font = UIFont.preferredFont(forTextStyle: .caption1)
                    l.textColor = .darkGray
            })
            stack.append(l)
        }
        
        stack.append(LabelLayout(
            text: track.track.track.title,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "trackTitle",
            config: nil
        ))
        
        if let dur = track.track.track.duration, track.artist.features.track_durations {
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
            viewReuseId: "sourceDetailsLayout",
            sublayout: StackLayout(
                axis: .horizontal,
                spacing: 8,
                sublayouts: stack
            )
        )
    }
}

public class TrackActions {
    public static func showActionOptions(fromViewController vc: UIViewController, forTrack info: CompleteTrackShowInformation) {
        let duration = info.track.track.duration?.humanize()
        
        let a = UIAlertController(
            title: "\(info.track.track.title) \((duration == nil ? "" : "(\(duration!)" )))",
            message: "\(info.source.display_date) — \(info.artist.name)",
            preferredStyle: .actionSheet
        )
        
        a.addAction(UIAlertAction(title: "Play Now", style: .default, handler: { _ in
            self.play(track: info, fromViewController: vc)
            PlaybackController.sharedInstance.dismiss()
        }))
        
        a.addAction(UIAlertAction(title: "Play Next", style: .default, handler: { _ in
            let ai = info.track.track.toAudioItem(inSource: info.source, fromShow: info.show, byArtist: info.artist)
            PlaybackController.sharedInstance.playbackQueue.insert(ai, at: UInt(PlaybackController.sharedInstance.player.currentIndex) + UInt(1))
            PlaybackController.sharedInstance.dismiss()
        }))
        
        a.addAction(UIAlertAction(title: "Add to End of Queue", style: .default, handler: { _ in
            let ai = info.track.track.toAudioItem(inSource: info.source, fromShow: info.show, byArtist: info.artist)
            PlaybackController.sharedInstance.playbackQueue.append(ai)
            PlaybackController.sharedInstance.dismiss()
        }))
        
        a.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in
            PlaybackController.sharedInstance.dismiss()
        }))
        
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            PlaybackController.sharedInstance.dismiss()
        }))
        
        PlaybackController.sharedInstance.hideMini()
        vc.present(a, animated: true, completion: nil)
    }
    
    public static func play(trackAtIndexPath idx: IndexPath, inShow info: CompleteShowInformation, fromViewController vc: UIViewController) {
        play(trackAtIndex: UInt(info.source.flattenedIndex(forIndexPath: idx)), inShow: info, fromViewController: vc)
     }
    
    public static func play(trackAtIndex: UInt, inShow info: ICompleteShowInformation, fromViewController vc: UIViewController) {
        let items = info.source.toAudioItems(inShow: info.show, byArtist: info.artist)
        
        PlaybackController.sharedInstance.playbackQueue.clearAndReplace(with: items)
        
        PlaybackController.sharedInstance.displayMini(on: vc, completion: nil)
        
        PlaybackController.sharedInstance.player.playItem(at: trackAtIndex)
    }
    
    public static func play(track info: CompleteTrackShowInformation, fromViewController vc: UIViewController) {
        var idx: UInt = 0
        for set in info.source.sets {
            for track in set.tracks {
                if track.id == info.track.track.id {
                    break
                }
                
                idx = idx + 1
            }
        }
        
        play(trackAtIndex: idx, inShow: info, fromViewController: vc)
    }
}
