 //
//  AGAudioPlayer.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <AVFoundation/AVFoundation.h>
#import "AGAudioItem.h"
#import "AGAudioPlayerUpNextQueue.h"

typedef NS_ENUM(NSInteger, AGAudioPlayerBackwardStyle) {
    AGAudioPlayerBackwardStyleRestartTrack,
    AGAudioPlayerBackwardStyleAlwaysPrevious
};

@class AGAudioPlayer;

typedef NS_ENUM(NSInteger, AGAudioPlayerRedrawReason) {
    AGAudioPlayerRedrawReasonBuffering,
    AGAudioPlayerRedrawReasonPlaying,
    AGAudioPlayerRedrawReasonStopped,
    AGAudioPlayerRedrawReasonPaused,
    AGAudioPlayerRedrawReasonError,
    AGAudioPlayerRedrawReasonTrackChanged,
    AGAudioPlayerRedrawReasonQueueChanged
};

/// all methods are always called on the main thread
@protocol AGAudioPlayerDelegate <NSObject>

- (void)audioPlayer:(AGAudioPlayer * _Nonnull)audioPlayer
uiNeedsRedrawForReason:(AGAudioPlayerRedrawReason)reason;

- (void)audioPlayer:(AGAudioPlayer * _Nonnull)audioPlayer
        errorRaised:(NSError * _Nonnull)error
             forURL:(NSURL * _Nonnull)url;

- (void)audioPlayer:(AGAudioPlayer * _Nonnull)audioPlayer
downloadedBytesForActiveTrack:(uint64_t)downloadedBytes
         totalBytes:(uint64_t)totalBytes;

- (void)audioPlayer:(AGAudioPlayer * _Nonnull)audioPlayer
    progressChanged:(NSTimeInterval)elapsed
  withTotalDuration:(NSTimeInterval)totalDuration;

- (void)audioPlayerAudioSessionSetUp:(AGAudioPlayer * _Nonnull)audioPlayer;

@optional

// OPTIONAL: if not implemented, will pause playback
- (void)audioPlayerBeginInterruption:(AGAudioPlayer * _Nonnull)audioPlayer;

// OPTIONAL: if not implemented, will resume playback if resume == YES
- (void)audioPlayerEndInterruption:(AGAudioPlayer * _Nonnull)audioPlayer
                      shouldResume:(BOOL)resume;

@end

// delegate for redraw with reason

@interface AGAudioPlayer : NSObject

- (_Nonnull instancetype)initWithQueue:(AGAudioPlayerUpNextQueue * _Nonnull)queue;

@property (nonatomic, weak) id<AGAudioPlayerDelegate> _Nullable delegate;

@property (nonatomic) AGAudioPlayerUpNextQueue * _Nonnull queue;

@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, readonly) AGAudioItem * _Nullable currentItem;

// returns NSNotFound when last item is playing
@property (nonatomic, readonly) NSInteger nextIndex;

// returns nil when last item is playing
@property (nonatomic, readonly) AGAudioItem * _Nullable nextItem;

// returns NSNotFound when the first item playing
@property (nonatomic, readonly) NSInteger previousIndex;

// returns nil when the first item is playing
@property (nonatomic, readonly) AGAudioItem * _Nullable previousItem;

// playback control
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isBuffering;
@property (nonatomic, readonly) BOOL isPlayingFirstItem;
@property (nonatomic, readonly) BOOL isPlayingLastItem;

@property (nonatomic) BOOL shuffle;

// loops
@property (nonatomic) BOOL loopQueue;
@property (nonatomic) BOOL loopItem;

@property (nonatomic) AGAudioPlayerBackwardStyle backwardStyle;

- (void)setIndex:(NSInteger)index;

- (void)resume;
- (void)pause;
- (void)stop;

- (BOOL)forward;
- (BOOL)backward;

- (void)seekTo:(NSTimeInterval)i;
- (void)seekToPercent:(CGFloat)per;

- (void)playItemAtIndex:(NSUInteger)idx;

// info
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval elapsed;
@property (nonatomic, readonly) CGFloat percentElapsed;

@property (nonatomic) CGFloat volume;

@end
