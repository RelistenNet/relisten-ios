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

public protocol TrackStatusActionHandler {
    func trackButtonTapped(_ button: UIButton, forTrack track: CompleteTrackShowInformation)
}

public protocol ICompleteShowInformation {
    var source: SourceFull { get }
    var show: Show { get }
    var artist: SlimArtistWithFeatures { get }
}

public class CompleteShowInformation : ICompleteShowInformation, Codable {
    public let source: SourceFull
    public let show: Show
    public let artist: SlimArtistWithFeatures
    
    public typealias CacheType = CompleteShowInformation
    public var originalJSON: SwJSON

    public required init(source: SourceFull, show: Show, artist: SlimArtistWithFeatures) {
        self.source = source
        self.show = show
        self.artist = artist
        
        var j = SwJSON([:])
        j["source"] = source.originalJSON
        j["show"] = show.originalJSON
        j["artist"] = artist.originalJSON
        
        originalJSON = j
    }
    
    public required init(json: SwJSON) throws {
        source = try SourceFull(json: ["source"])
        show = try Show(json: json["show"])
        artist = try SlimArtistWithFeatures(json: json["artist"])

        originalJSON = json
    }
    
    public convenience required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .originalJson)
        
        try self.init(json: SwJSON(data: data))
    }
    
    public func toPrettyJSONString() -> String {
        return originalJSON.rawString(.utf8, options: .prettyPrinted)!
    }
    
    public func toData() throws -> Data {
        return try originalJSON.rawData()
    }
    
    enum CodingKeys: String, CodingKey
    {
        case originalJson
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toData(), forKey: .originalJson)
    }
}

public struct CompleteTrackShowInformation : ICompleteShowInformation, Codable, Hashable {
    public var hashValue: Int {
        return track.track.mp3_url.hashValue ^ artist.id.hashValue ^ show.display_date.hashValue
    }
    
    public static func == (lhs: CompleteTrackShowInformation, rhs: CompleteTrackShowInformation) -> Bool {
        return lhs.artist.id == rhs.artist.id
            && lhs.show.display_date == rhs.show.display_date
            && lhs.track.track.mp3_url == rhs.track.track.mp3_url
    }
    
    public let track: TrackStatus
    public let source: SourceFull
    public let show: Show
    public let artist: SlimArtistWithFeatures
}

public class TrackStatusLayout : InsetLayout<UIView> {
    public init(withTrack track: CompleteTrackShowInformation, withHandler handler: TrackStatusActionHandler, usingExplicitTrackNumber: Int? = nil, showingArtistInformation: Bool = false) {
        var stack : [Layout] = []
        
        if track.track.isActiveTrack {
            // 24x16 in total
            let l = InsetLayout(
                insets: UIEdgeInsetsMake(2, 0, 2, 12),
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
                        p.state = track.track.isPlaying ? .playing : .paused
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
                    l.text = String(describing: usingExplicitTrackNumber ?? track.track.track.track_position)
                    l.font = UIFont.preferredFont(forTextStyle: .caption1)
                    l.textColor = .darkGray
            })
            stack.append(l)
        }
        
        var potentialOfflineLayout: Layout? = nil
        
        let availableOffline = track.track.isAvailableOffline
        let activelyDownloading = track.track.isActivelyDownloading
        
        if availableOffline || track.track.isQueuedToDownload || activelyDownloading {
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
                    imageV.image = availableOffline ? UIImage(named: "download-complete") : UIImage(named: "download-active")
                    
                    if activelyDownloading {
                        imageV.alpha = 1.0
                        UIView.animate(withDuration: 1.0,
                                       delay: 0,
                                       options: [UIViewAnimationOptions.autoreverse, UIViewAnimationOptions.repeat],
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
        }
        
        if let p = potentialOfflineLayout, !showingArtistInformation {
            stack.append(InsetLayout(insets: EdgeInsets(top: 0, left: 0, bottom: 0, right: 8), sublayout: p))
        }
        
        let trackTitleLabel = LabelLayout(
            text: track.track.track.title,
            font: UIFont.preferredFont(forTextStyle: .body),
            numberOfLines: 0,
            alignment: .fillLeading,
            flexibility: .flexible,
            viewReuseId: "trackTitle",
            config: nil
        )
        
        if showingArtistInformation {
            let artistInfoLabel = LabelLayout(
                text: track.artist.name + " • " + track.show.display_date,
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
        
        if let dur = track.track.track.duration, track.artist.features.track_durations {
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
            
            stack.append(InsetLayout(insets: UIEdgeInsetsMake(0, 8, 0, 0), sublayout: label))
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
                spacing: 0,
                sublayouts: stack
            )
        )
    }
}
