//
//  RemoteCommandManager.swift
//  AGAudioPlayer
//
//  Created by Alec Gorge on 9/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 `RemoteCommandManager` contains all the APIs calls to MPRemoteCommandCenter to enable and disable various remote control events.
 */

import Foundation
import MediaPlayer

@objc class RemoteCommandManager: NSObject {
    
    // MARK: Properties
    
    /// Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    /// The instance of `AssetPlaybackManager` to use for responding to remote command events.
    weak var player: AGAudioPlayer?
    
    // MARK: Initialization.
    
    init(player: AGAudioPlayer) {
        self.player = player
    }
    
    deinit {
        
        #if os(tvOS)
            activatePlaybackCommands(false)
        #endif
        
        activatePlaybackCommands(false)
        toggleNextTrackCommand(false)
        togglePreviousTrackCommand(false)
        toggleSkipForwardCommand(false)
        toggleSkipBackwardCommand(false)
        toggleChangePlaybackPositionCommand(false)
        toggleLikeCommand(false)
        toggleDislikeCommand(false)
        toggleBookmarkCommand(false)
    }
    
    // MARK: MPRemoteCommand Activation/Deactivation Methods
    
    #if os(tvOS)
    func activateRemoteCommands(_ enable: Bool) {
    activatePlaybackCommands(enable)
    
    // To support Siri's "What did they say?" command you have to support the appropriate skip commands.  See the README for more information.
    toggleSkipForwardCommand(enable, interval: 15)
    toggleSkipBackwardCommand(enable, interval: 20)
    }
    #endif
    
    func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
            
        }
        else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
        }
        
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
        
        toggleChangePlaybackPositionCommand(enable)
        toggleNextTrackCommand(enable)
        togglePreviousTrackCommand(enable)
    }
    
    func toggleNextTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        else {
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
    }
    
    func togglePreviousTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    func toggleSkipForwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipForwardCommand.isEnabled = enable
    }
    
    func toggleSkipBackwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipBackwardCommand.isEnabled = enable
    }
    
    func toggleChangePlaybackPositionCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = enable
    }
    
    func toggleLikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.likeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.likeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.likeCommand.isEnabled = enable
    }
    
    func toggleDislikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.dislikeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.dislikeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.dislikeCommand.isEnabled = enable
    }
    
    func toggleBookmarkCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.bookmarkCommand.addTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.bookmarkCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
        }
        
        remoteCommandCenter.bookmarkCommand.isEnabled = enable
    }
    
    // MARK: MPRemoteCommand handler methods.
    
    // MARK: Playback Command Handlers
    @objc func handlePauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        player?.pause()
        
        return .success
    }
    
    @objc func handlePlayCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        player?.resume()
        
        return .success
    }
    
    @objc func handleStopCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        player?.stop()
        
        return .success
    }
    
    @objc func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let b = player?.isPlaying, b {
            player?.pause()
        }
        else {
            player?.resume()
        }
        
        return .success
    }
    
    // MARK: Track Changing Command Handlers
    @objc func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let p = player, p.forward() {
            return .success
        }
        
        return .noSuchContent
    }
    
    @objc func handlePreviousTrackCommandEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let p = player, p.backward() {
            return .success
        }
        
        return .noSuchContent
    }
    
    // MARK: Skip Interval Command Handlers
    @objc func handleSkipForwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let p = player {
            p.seek(to: p.elapsed + event.interval)
        }
        
        return .success
    }
    
    @objc func handleSkipBackwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let p = player {
            p.seek(to: p.elapsed - event.interval)
        }

        return .success
    }
    
    @objc func handleChangePlaybackPositionCommandEvent(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let p = player {
            p.seek(to: event.positionTime)
        }
        
        return .success
    }
    
    // MARK: Feedback Command Handlers
    @objc func handleLikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("Did recieve likeCommand for")
        return .noSuchContent
    }
    
    @objc func handleDislikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("Did recieve dislikeCommand for")
        return .noSuchContent
    }
    
    @objc func handleBookmarkCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("Did recieve bookmarkCommand for")
        return .noSuchContent
    }
}

// MARK: Convienence Category to make it easier to expose different types of remote command groups as the UITableViewDataSource in RemoteCommandListTableViewController.
extension RemoteCommandManager {
    
}
