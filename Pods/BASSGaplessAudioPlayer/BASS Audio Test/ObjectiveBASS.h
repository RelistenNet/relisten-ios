//
//  ObjectiveBASS.h
//  BASS Audio Test
//
//  Created by Alec Gorge on 10/20/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "bass.h"
#include "bassmix.h"

typedef NS_ENUM(NSInteger, BassPlaybackState) {
    BassPlaybackStateStopped = BASS_ACTIVE_STOPPED,
    BassPlaybackStatePlaying = BASS_ACTIVE_PLAYING,
    BassPlaybackStatePaused  = BASS_ACTIVE_PAUSED,
    BassPlaybackStateStalled = BASS_ACTIVE_STALLED
};

typedef NS_ENUM(NSInteger, BassStreamError) {
    BassStreamErrorInit = BASS_ERROR_INIT,
    BassStreamErrorNotAvail = BASS_ERROR_NOTAVAIL,
    BassStreamErrorNoInternet = BASS_ERROR_NONET,
    BassStreamErrorInvalidUrl = BASS_ERROR_ILLPARAM,
    BassStreamErrorSslUnsupported = BASS_ERROR_SSL,
    BassStreamErrorServerTimeout = BASS_ERROR_TIMEOUT,
    BassStreamErrorCouldNotOpenFile = BASS_ERROR_FILEOPEN,
    BassStreamErrorFileInvalidFormat = BASS_ERROR_FILEFORM,
    BassStreamErrorSupportedCodec = BASS_ERROR_CODEC,
    BassStreamErrorUnsupportedSampleFormat = BASS_ERROR_SPEAKER,
    BassStreamErrorInsufficientMemory = BASS_ERROR_MEM,
    BassStreamErrorNo3D = BASS_ERROR_NO3D,
    BassStreamErrorUnknown = BASS_ERROR_UNKNOWN // oh shit
};

@class ObjectiveBASS;

@protocol ObjectiveBASSDataSource <NSObject>

/// url and identifier are self.currentlyPlayingURL and currentlyPlayingIdentifier
- (BOOL)BASSIsPlayingLastTrack:(nonnull ObjectiveBASS *)bass
                       withURL:(nonnull NSURL *)url
                 andIdentifier:(nonnull NSUUID *)identifier;

- (nonnull NSUUID *)BASSNextTrackIdentifier:(nonnull ObjectiveBASS *)bass
                                   afterURL:(nonnull NSURL *)url
                             withIdentifier:(nonnull NSUUID *)identifier;

- (void)BASSLoadNextTrackURL:(nonnull ObjectiveBASS *)bass
               forIdentifier:(nonnull NSUUID *)identifier;

@end

@protocol ObjectiveBASSDelegate <NSObject>

- (void)BASSDownloadProgressChanged:(BOOL)forActiveTrack
                    downloadedBytes:(uint64_t)downloadedBytes
                         totalBytes:(uint64_t)totalBytes;

- (void)BASSPlaybackProgressChanged:(NSTimeInterval)elapsed
                  withTotalDuration:(NSTimeInterval)totalDuration;

- (void)BASSDownloadPlaybackStateChanged:(BassPlaybackState)state;

- (void)BASSErrorStartingStream:(nonnull NSError *)error
                         forURL:(nonnull NSURL *)url
                 withIdentifier:(nonnull NSUUID *)identifier;

- (void)BASSFinishedPlayingGUID:(nonnull NSUUID *)identifier
                         forURL:(nonnull NSURL *)url;

- (void)BASSAudioSessionSetUp;

@end

@interface ObjectiveBASS : NSObject

#pragma mark - Lifecyle

@property (nonatomic, weak) _Nullable id<ObjectiveBASSDataSource> dataSource;
@property (nonatomic, weak) _Nullable id<ObjectiveBASSDelegate> delegate;

#pragma mark - FX

@property (nonatomic) BOOL eqEnable;
@property (nonatomic) float eqBassGain;
@property (nonatomic) float eqMidGain;
@property (nonatomic) float eqTrebleGain;

#pragma mark - Currently Playing

@property (nonatomic, readonly) NSURL * _Nullable currentlyPlayingURL;
@property (nonatomic, readonly) NSUUID * _Nullable currentlyPlayingIdentifier;

#pragma mark - Next Track

@property (nonatomic, readonly) NSURL * _Nullable nextURL;
@property (nonatomic, readonly) NSUUID * _Nullable nextIdentifier;

- (void)nextTrackChanged;
- (void)nextTrackMayHaveChanged;
- (void)nextTrackURLLoaded:(nonnull NSURL *)url;

#pragma mark - Playback Controls

@property (nonatomic, readonly) BassPlaybackState currentState;

@property (nonatomic, readonly) NSTimeInterval currentDuration;
@property (nonatomic, readonly) NSTimeInterval elapsed;

@property (nonatomic, readonly) NSUInteger downloadedBytes;
@property (nonatomic, readonly) NSUInteger totalFileBytes;

@property (nonatomic) float volume;

- (void)seekToPercent:(float)pct;

- (void)resume;
- (void)pause;
- (void)next;
- (void)stop;

- (void)playURL:(nonnull NSURL *)url
 withIdentifier:(nonnull NSUUID *)identifier;

- (void)playURL:(nonnull NSURL *)url
 withIdentifier:(nonnull NSUUID *)identifier
     startingAt:(float)pct;

- (NSError * _Nonnull)errorForErrorCode:(BassStreamError)erro;

@end
