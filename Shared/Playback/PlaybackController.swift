//
//  PlaybackController.swift
//  Relisten
//
//  Created by Alec Gorge on 7/3/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import AGAudioPlayer

public class PlaybackController {
    public let playbackQueue: AGAudioPlayerUpNextQueue
    public let player: AGAudioPlayer
    public let viewController: AGAudioPlayerViewController
    
    public static let sharedInstance = PlaybackController()
    
    public required init() {
        playbackQueue = AGAudioPlayerUpNextQueue()
        player = AGAudioPlayer(queue: playbackQueue)
        viewController = AGAudioPlayerViewController(player: player)
        
        viewController.loadViewIfNeeded()
    }
    
    public func display(on vc: UIViewController, completion: (() -> Void)?) {
        vc.present(viewController, animated: true, completion: completion)
    }
    
    public func dismiss(_ completion: (() -> Void)? = nil) {
        if let presenter = viewController.presentingViewController {
            presenter.dismiss(animated: true, completion: completion)
        }
    }
}
