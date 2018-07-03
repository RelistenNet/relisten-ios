//
//  ObjectiveBASS.m
//  BASS Audio Test
//
//  Created by Alec Gorge on 10/20/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

#import "ObjectiveBASS.h"

#import <AVFoundation/AVFoundation.h>

#import "bass_fx.h"

extern void BASSFXplugin;

#define dbug NSLog

#define VISUALIZATION_BUF_SIZE 4096

@interface ObjectiveBassStream : NSObject

@property (nonatomic) BOOL preloadStarted;
@property (nonatomic) BOOL preloadFinished;

@property (nonatomic) HSTREAM stream;

@property (nonatomic) DWORD fileOffset;
@property (nonatomic) QWORD channelOffset;

@property (nonatomic) NSURL * _Nullable url;
@property (nonatomic) NSUUID * _Nullable identifier;

@end

@implementation ObjectiveBassStream

- (instancetype)init {
    if (self = [super init]) {
        [self clear];
    }
    return self;
}

- (void)clear {
    _preloadStarted =
    _preloadFinished = NO;
    
    _stream = 0;
    _fileOffset = 0;
    _channelOffset = 0;
    
    _url = nil;
    _identifier = nil;
}

@end

@interface ObjectiveBASS (){
    
@private
    HSTREAM mixerMaster;
    
    ObjectiveBassStream *streams[2];
    NSUInteger activeStreamIdx;
    
    BOOL isInactiveStreamUsed;
    
    dispatch_queue_t queue;
    
    BassPlaybackState _currentState;
    
    BOOL audioSessionAlreadySetUp;
    BOOL wasPlayingWhenInterrupted;
    
    float *visualizationBuf[VISUALIZATION_BUF_SIZE];
    
    BOOL seeking;
    
    HFX fxLowShelf;
    HFX fxBandPass;
    HFX fxHighShelf;
    
    BASS_BFX_BQF fxParamsLowShelf;
    BASS_BFX_BQF fxParamsBandPass;
    BASS_BFX_BQF fxParamsHighShelf;
}

@property (nonatomic) ObjectiveBassStream *activeStream;
@property (nonatomic) ObjectiveBassStream *inactiveStream;

- (void)mixInNextTrack:(HSTREAM)completedStream;
- (void)streamDownloadComplete:(HSTREAM)stream;

- (void)streamStalled:(HSTREAM)stream;
- (void)streamResumedAfterStall:(HSTREAM)stream;

@end

/*
void CALLBACK StreamDownloadProc(const void *buffer,
                                 DWORD length,
                                 void *user) {
    if(length > 4 && strncmp(buffer, "HTTP", 4) == 0) {
        dbug(@"[bass][StreamDownloadProc] received %u bytes.", length);
        dbug(@"[bass][StreamDownloadProc] HTTP data: %@", [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding]);
    }
}
*/

void CALLBACK MixerEndSyncProc(HSYNC handle,
                               DWORD channel,
                               DWORD data,
                               void *user) {
    ObjectiveBASS *self = (__bridge ObjectiveBASS *)user;
    [self mixInNextTrack:channel];
}

void CALLBACK StreamDownloadCompleteSyncProc(HSYNC handle,
                                             DWORD channel,
                                             DWORD data,
                                             void *user) {
    // channel is the HSTREAM we created before
    dbug(@"[bass][stream] stream download completed: handle: %u. channel: %u", handle, channel);
    ObjectiveBASS *self = (__bridge ObjectiveBASS *)user;
    [self streamDownloadComplete:channel];
}

void CALLBACK StreamStallSyncProc(HSYNC handle,
                                  DWORD channel,
                                  DWORD data,
                                  void *user) {
    // channel is the HSTREAM we created before
    dbug(@"[bass][stream] stream stall: handle: %u. channel: %u", handle, channel);
    ObjectiveBASS *self = (__bridge ObjectiveBASS *)user;
    
    if(data == 0 /* stalled */) {
        [self streamStalled:channel];
    }
    else if(data == 1 /* resumed */) {
        [self streamResumedAfterStall:channel];
    }
}

@implementation ObjectiveBASS

- (void)stopAndResetInactiveStream {
    // no assert because this might fail
    BASS_ChannelStop(self.inactiveStream.stream);
    
    [self.inactiveStream clear];
    
    isInactiveStreamUsed = NO;
}

- (void)nextTrackChanged {
    // don't do anything if we aren't currently playing something
    if(self.currentlyPlayingIdentifier == nil) {
        return;
    }

    if ([self.dataSource BASSIsPlayingLastTrack:self
                                        withURL:self.currentlyPlayingURL
                                  andIdentifier:self.currentlyPlayingIdentifier]) {
        [self stopAndResetInactiveStream];
    }
    else {
        NSUUID *oldNext = self.inactiveStream.identifier;
        
        self.inactiveStream.identifier = [self.dataSource BASSNextTrackIdentifier:self
                                                                         afterURL:self.currentlyPlayingURL
                                                                   withIdentifier:self.currentlyPlayingIdentifier];
        
        if(![self.inactiveStream.identifier isEqual:oldNext]) {
            [self.dataSource BASSLoadNextTrackURL:self
                                    forIdentifier:self.nextIdentifier];            
        }
    }
}

- (void)nextTrackMayHaveChanged {
    [self nextTrackChanged];
}

- (void)nextTrackURLLoaded:(NSURL *)url {
    dispatch_async(queue, ^{
        [self _nextTrackURLLoaded:url];
    });
}

- (void)_nextTrackURLLoaded:(NSURL *)url {
    if(isInactiveStreamUsed) {
        BASS_ChannelStop(self.inactiveStream.stream);
    }
    
    self.inactiveStream.url = url;
    
    if(self.activeStream.preloadFinished || self.activeStream.url.isFileURL) {
        dbug(@"[bass][stream] active stream preload complete, preloading next");
        [self setupInactiveStreamWithNext];
        
        // this is needed because the stream download events don't fire for local music
        if(self.activeStream.url.isFileURL) {
            [self streamDownloadComplete:self.activeStream.stream];
        }
    }
    else {
        dbug(@"[bass][stream] active stream preload NOT complete, NOT preloading next");
    }
}

- (BOOL)hasNextTrackChanged {
    BOOL isPlayingLast = [self.dataSource BASSIsPlayingLastTrack:self
                                                         withURL:self.currentlyPlayingURL
                                                   andIdentifier:self.currentlyPlayingIdentifier];
    
    if(!self.hasNextURL && !isPlayingLast) {
        return YES;
    }
    else if(self.hasNextURL && isPlayingLast) {
        return YES;
    }
    else if(self.hasNextURL && self.nextIdentifier != [self.dataSource BASSNextTrackIdentifier:self
                                                                                      afterURL:self.currentlyPlayingURL
                                                                                withIdentifier:self.currentlyPlayingIdentifier]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)updateNextTrackIfNecessary {
    if([self hasNextTrackChanged]) {
        [self nextTrackChanged];
        return YES;
    }
    
    return NO;
}

#pragma mark - Active/Inactive Stream Managment

- (void)toggleActiveStream {
    activeStreamIdx = activeStreamIdx == 1 ? 0 : 1;
}

- (ObjectiveBassStream *)activeStream {
    return streams[activeStreamIdx];
}

- (ObjectiveBassStream *)inactiveStream {
    return streams[activeStreamIdx == 1 ? 0 : 1];
}

#pragma mark - Order Management

- (BOOL)hasNextURL {
    return self.inactiveStream.url != nil;
}

#pragma mark - BASS Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        queue = dispatch_queue_create("com.alecgorge.ios.objectivebass", NULL);
        [self setupBASS];
    }
    return self;
}

- (void)dealloc {
    [self teardownBASS];
    [self teardownAudioSession];
}

- (void)setupBASS {
    dispatch_async(queue, ^{
        // BASS_SetConfigPtr(BASS_CONFIG_NET_PROXY, "192.168.1.196:8888");
        BASS_SetConfig(BASS_CONFIG_NET_TIMEOUT, 15 * 1000);
        
        // we'll manage ourselves, thanks.
        BASS_SetConfig(BASS_CONFIG_IOS_NOCATEGORY, 1);
        
        assert(BASS_Init(-1, 44100, 0, NULL, NULL));
        
        if (HIWORD(BASS_FX_GetVersion()) != BASSVERSION) {
            // incorrect version loaded!
            assert(false); // wat
        }
        
        mixerMaster = BASS_Mixer_StreamCreate(44100, 2, BASS_MIXER_END);
        
        BASS_ChannelSetSync(mixerMaster, BASS_SYNC_END | BASS_SYNC_MIXTIME, 0, MixerEndSyncProc, (__bridge void *)(self));
        
        streams[0] = ObjectiveBassStream.new;
        streams[1] = ObjectiveBassStream.new;
        
        activeStreamIdx = 0;
        
        self.eqEnable = YES;
    });
}

- (void)teardownBASS {
    BASS_Free();
}

#pragma mark - FX

/*
 first filter: type = BASS_BFX_BQF_LOWSHELF, fQ = 1.0, fCenter = 125
 second filter: type = BASS_BFX_BQF_BANDPASS, fQ = 0.1, fCenter = 750
 third filter: type = BASS_BFX_BQF_HIGHSHELF, fQ = 1.0, fCenter = 5000
 then the iOS control for bass/mid/treble should correlate to changing fGain
 we may also want to apply a master gain on the output when extreme gains are used, in order to stop people from blowing up their headphones on the output - if iOS doesn’t already do that for us
 OH for the low shelf and high shelf you use fS = 0.0
 not fQ
 */
- (void)setupFX {
    fxLowShelf  = BASS_ChannelSetFX(mixerMaster, BASS_FX_BFX_BQF, 0);
    fxBandPass  = BASS_ChannelSetFX(mixerMaster, BASS_FX_BFX_BQF, 1);
    fxHighShelf = BASS_ChannelSetFX(mixerMaster, BASS_FX_BFX_BQF, 2);
    
    assert(fxLowShelf);
    assert(fxBandPass);
    assert(fxHighShelf);
    
    fxParamsLowShelf.lFilter = BASS_BFX_BQF_LOWSHELF;
    fxParamsLowShelf.fS = 1.0;
    fxParamsLowShelf.fCenter = 125;
    
    fxParamsBandPass.lFilter = BASS_BFX_BQF_BANDPASS;
    fxParamsBandPass.fQ = 0.1;
    fxParamsBandPass.fCenter = 750;
    
    fxParamsHighShelf.lFilter = BASS_BFX_BQF_HIGHSHELF;
    fxParamsHighShelf.fS = 1.0;
    fxParamsHighShelf.fCenter = 5000;
    
    assert(BASS_FXSetParameters(fxLowShelf, &fxParamsLowShelf));
    assert(BASS_FXSetParameters(fxBandPass, &fxParamsBandPass));
    assert(BASS_FXSetParameters(fxHighShelf, &fxParamsHighShelf));
}

- (void)teardownFX {
    BASS_ChannelRemoveFX(mixerMaster, fxLowShelf);
    BASS_ChannelRemoveFX(mixerMaster, fxBandPass);
    BASS_ChannelRemoveFX(mixerMaster, fxHighShelf);
    
    fxLowShelf =
    fxBandPass =
    fxHighShelf = 0;
}

- (void)setEqEnable:(BOOL)eqEnable {
    if(_eqEnable != eqEnable) {
        _eqEnable = eqEnable;
        
        if(_eqEnable) {
            [self setupFX];
        }
        else {
            [self teardownFX];
        }
    }
}

- (float)setGain:(float)gain
       inParams:(BASS_BFX_BQF *)params
          forFX:(HFX)fx {
    params->fGain = fminf(fmaxf(-12.0, gain), 12.0);
    
    assert(BASS_FXSetParameters(fx, params));
    
    return params->fGain;
}

- (void)setEqBassGain:(float)eqBassGain {
    [self setGain:eqBassGain inParams:&fxParamsLowShelf forFX:fxLowShelf];
}

- (void)setEqMidGain:(float)eqMidGain {
    [self setGain:eqMidGain inParams:&fxParamsBandPass forFX:fxBandPass];
}

- (void)setEqTrebleGain:(float)eqTrebleGain {
    [self setGain:eqTrebleGain inParams:&fxParamsHighShelf forFX:fxHighShelf];
}

- (float)eqBassGain {
    return fxParamsLowShelf.fGain;
}

- (float)eqMidGain {
    return fxParamsBandPass.fGain;
}

- (float)eqTrebleGain {
    return fxParamsHighShelf.fGain;
}

#pragma mark - URL Building

- (HSTREAM)buildStreamForURL:(NSURL *)url
              withFileOffset:(DWORD)fileOffset
               andIdentifier:(NSUUID *)identifier {
    HSTREAM newStream;
    
    if(url.isFileURL) {
        newStream = BASS_StreamCreateFile(FALSE,
                                          [url.path cStringUsingEncoding:NSUTF8StringEncoding],
                                          fileOffset,
                                          0,
                                          BASS_STREAM_DECODE | BASS_SAMPLE_FLOAT | BASS_ASYNCFILE | BASS_STREAM_PRESCAN);
    }
    else {
        newStream = BASS_StreamCreateURL([url.absoluteString cStringUsingEncoding:NSUTF8StringEncoding],
                                         fileOffset,
                                         BASS_STREAM_DECODE | BASS_SAMPLE_FLOAT,
                                         NULL, // StreamDownloadProc,
                                         NULL); // (__bridge void *)(self));
    }
    
    // oops
    if(newStream == 0) {
        NSError *err = [self errorForErrorCode:BASS_ErrorGetCode()];
        
        dbug(@"[bass][stream] error creating new stream: %ld %@", (long)err.code, err.localizedDescription);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate BASSErrorStartingStream:err
                                            forURL:url
                                    withIdentifier:identifier];
        });
        
        return 0;
    }
    
    assert(BASS_ChannelSetSync(newStream,
                               BASS_SYNC_MIXTIME | BASS_SYNC_DOWNLOAD,
                               0,
                               StreamDownloadCompleteSyncProc,
                               (__bridge void *)(self)));
    
    assert(BASS_ChannelSetSync(newStream,
                               BASS_SYNC_MIXTIME | BASS_SYNC_STALL,
                               0,
                               StreamStallSyncProc,
                               (__bridge void *)(self)));
    
    dbug(@"[bass][stream] created new stream: %u. Callstack:\n%@", newStream, NSThread.callStackSymbols);
    
    return newStream;
}

- (HSTREAM)buildAndSetupActiveStreamForURL:(NSURL *)url
                                          withIdentifier:(NSUUID *)ident {
    return [self buildAndSetupActiveStreamForURL:url
                                  withIdentifier:ident
                                      fileOffset:0
                                andChannelOffset:0];
}

- (HSTREAM)buildAndSetupActiveStreamForURL:(NSURL *)url
                            withIdentifier:(NSUUID *)ident
                                fileOffset:(DWORD)offset
                          andChannelOffset:(QWORD)channelOffset {
    dbug(@"[bass][stream] requesting build stream for ACTIVE");
    HSTREAM newStream = [self buildStreamForURL:url
                                 withFileOffset:offset
                                  andIdentifier:ident];
    
    if(newStream == 0) {
        return 0;
    }
    
    [self.activeStream clear];
    
    self.activeStream.stream = newStream;
    self.activeStream.identifier = ident;
    self.activeStream.url = url;
    self.activeStream.fileOffset = offset;
    self.activeStream.channelOffset = channelOffset;
    
    return self.activeStream.stream;
}

- (ObjectiveBassStream *)buildAndSetupInactiveStreamForURL:(NSURL *)url
                                            withIdentifier:(NSUUID *)ident {
    dbug(@"[bass][stream] requesting build stream for INACTIVE");
    HSTREAM newStream = [self buildStreamForURL:url withFileOffset:0 andIdentifier:ident];
    
    if(newStream == 0) {
        return 0;
    }
    
    [self.inactiveStream clear];
    
    self.inactiveStream.stream = newStream;
    self.inactiveStream.identifier = ident;
    self.inactiveStream.url = url;
    self.inactiveStream.fileOffset = 0;
    self.inactiveStream.channelOffset = 0;
    
    isInactiveStreamUsed = YES;
    
    return self.inactiveStream;
}

- (void)playURL:(nonnull NSURL *)url
 withIdentifier:(nonnull NSUUID *)identifier {
    [self playURL:url
   withIdentifier:identifier
       startingAt:0.0f];
}

- (void)playURL:(nonnull NSURL *)url
 withIdentifier:(nonnull NSUUID *)identifier
     startingAt:(float)pct {
    [self setupAudioSession: YES];

    if(self.currentlyPlayingURL != nil && self.hasNextURL && [identifier isEqual:self.nextIdentifier] && isInactiveStreamUsed) {
        [self next];
        return;
    }
    else if([identifier isEqual:self.currentlyPlayingIdentifier]) {
        [self seekToPercent:0.0f];
        
        return;
    }
    
    dispatch_async(queue, ^{
        // stop playback
        assert(BASS_ChannelStop(mixerMaster));
        
        // stop channels to allow them to be freed
        BASS_ChannelStop(self.activeStream.stream);
        
        // remove this stream from the mixer
        // not assert'd because sometimes it should fail (initial playback)
        BASS_Mixer_ChannelRemove(self.activeStream.stream);
        
        // do the same thing for inactive--but only if the next track is actually different
        // and if something is currently playing
        if(self.currentlyPlayingURL != nil && [self hasNextTrackChanged]) {
            BASS_ChannelStop(self.inactiveStream.stream);
            BASS_Mixer_ChannelRemove(self.inactiveStream.stream);
        }
        
        if([self buildAndSetupActiveStreamForURL:url
                                  withIdentifier:identifier] != 0) {
            assert(BASS_Mixer_StreamAddChannel(mixerMaster,
                                               self.activeStream.stream,
                                               BASS_STREAM_AUTOFREE | BASS_MIXER_NORAMPIN));
            
            // the TRUE for the second argument clears the buffer so there isn't old sound playing
            assert(BASS_ChannelPlay(mixerMaster, TRUE));
            
            [self changeCurrentState:BassPlaybackStatePlaying];
            
            [self nextTrackMayHaveChanged];
        }
    });
    
    [self startUpdates];
}

- (void)startUpdates {
    NSTimeInterval oldElapsed = self.elapsed;
    NSTimeInterval oldDuration = self.currentDuration;
    BassPlaybackState prevState = _currentState;

    QWORD oldDownloadedBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_DOWNLOAD);
    QWORD oldTotalFileBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_SIZE);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), queue, ^{
        NSTimeInterval elapsed = self.elapsed;
        NSTimeInterval duration = self.currentDuration;
        
        QWORD downloadedBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_DOWNLOAD);
        QWORD totalFileBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_SIZE);
        
        BOOL sendPlaybackChanged = NO;
        BOOL sendDownloadChanged = NO;
        BOOL sendStateChanged    = NO;
        
        if(oldElapsed != elapsed || oldDuration != duration) {
            sendPlaybackChanged = YES;
        }
        
        if((downloadedBytes != -1 || totalFileBytes != -1 || oldTotalFileBytes != -1 || oldTotalFileBytes != -1)
        && (oldDownloadedBytes != downloadedBytes || oldTotalFileBytes != totalFileBytes)) {
            sendDownloadChanged = YES;
        }
        
        BassPlaybackState currState = self.currentState;
        if(prevState != currState) {
            sendStateChanged = YES;
        }
        
        if(sendStateChanged || sendDownloadChanged || sendPlaybackChanged) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(sendPlaybackChanged) {
                    [self.delegate BASSPlaybackProgressChanged:elapsed
                                             withTotalDuration:duration];
                }
                
                if(sendDownloadChanged) {
                    [self.delegate BASSDownloadProgressChanged:YES
                                               downloadedBytes:downloadedBytes
                                                    totalBytes:totalFileBytes];
                }
                
                if(sendStateChanged) {
                    [self.delegate BASSDownloadPlaybackStateChanged:currState];
                }
            });
        }
        
        /*
        DWORD len = BASS_ChannelGetData(self.activeStream, visualizationBuf, VISUALIZATION_BUF_SIZE);
        
        if(len != -1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate BASSDidReceiveBuffer:(float *)visualizationBuf
                                             length:len];
            });
        }
         */
        
        [self startUpdates];
    });
}

- (void)streamStalled:(HSTREAM)stream {
    if(stream == self.activeStream.stream) {
        [self changeCurrentState:BassPlaybackStateStalled];
    }
}

- (void)streamResumedAfterStall:(HSTREAM)stream {
    if(stream == self.activeStream.stream) {
        [self changeCurrentState:BassPlaybackStatePlaying];
    }
}

- (void)streamDownloadComplete:(HSTREAM)stream {
    if(stream == self.activeStream.stream) {
        if(!self.activeStream.preloadFinished) {
            self.activeStream.preloadFinished = YES;
            
            // active stream has fully loaded, load the next one
            if(![self updateNextTrackIfNecessary]) {
                [self setupInactiveStreamWithNext];
            }
        }
    }
    else if(stream == self.inactiveStream.stream) {
        self.inactiveStream.preloadStarted = YES;
        self.inactiveStream.preloadFinished = YES;
        
        // the inactive stream is also loaded--good, but we don't want to load anything else
        // we do want to start decoding the downloaded data though
        
        // The amount of data to render, in milliseconds... 0 = default (2 x update period)
        // assert(BASS_ChannelUpdate(self.inactiveStream, 0));
    }
    else {
        dbug(@"[bass][ERROR] whoa, unknown stream finished downloading: %u", stream);
        // assert(FALSE);
    }
}

- (void)setupInactiveStreamWithNext {
    if(self.hasNextURL) {
        dbug(@"[bass] Next index found. Setting up next stream.");
        BASS_Mixer_ChannelRemove(self.inactiveStream.stream);
        
        if([self buildAndSetupInactiveStreamForURL:self.nextURL
                                    withIdentifier:self.nextIdentifier] != 0) {
            [self startPreloadingInactiveStream];
        }
    }
    else {
        isInactiveStreamUsed = NO;
        
        [self.inactiveStream clear];
    }
}

- (void)startPreloadingInactiveStream {
    // don't start loading anything until the active stream has finished
    if(!self.activeStream.preloadFinished) {
        return;
    }

    dbug(@"[bass][preloadNextTrack] Preloading next track");
    BASS_ChannelUpdate(self.inactiveStream.stream, 0);
    self.inactiveStream.preloadStarted = YES;
}

- (void)notifyDelegateThatTrackChanged:(NSUUID *)oldIdentifier
                               withURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate BASSFinishedPlayingGUID:oldIdentifier
                                        forURL:url];        
    });
}

- (void)mixInNextTrack:(HSTREAM)completedTrack {
    dbug(@"[bass][MixerEndSyncProc] End Sync called for stream: %u", completedTrack);
    
    if(completedTrack != self.activeStream.stream && completedTrack != mixerMaster) {
        dbug(@"[bass][MixerEndSyncProc] completed stream is no longer active: %u", completedTrack);
        return;
    }
    
    HSTREAM previouslyInactiveStream = self.inactiveStream.stream;
    
    NSUUID *previouslyActiveGUID = self.currentlyPlayingIdentifier;
    NSURL *previouslyActiveURL = self.currentlyPlayingURL;
    
    if([self updateNextTrackIfNecessary]) {
        // track updated, do nothing
        [self notifyDelegateThatTrackChanged:previouslyActiveGUID
                                     withURL:previouslyActiveURL];
        
        return;
    }
    
    if([self hasNextURL] && !isInactiveStreamUsed) {
        dbug(@"[bass][stream] playback of %d finished and there is a next URL but there isn't a next stream. setting up", completedTrack);
        [self setupInactiveStreamWithNext];
    }
    
    if(isInactiveStreamUsed) {
        assert(BASS_Mixer_StreamAddChannel(mixerMaster,
                                           previouslyInactiveStream,
                                           BASS_STREAM_AUTOFREE | BASS_MIXER_NORAMPIN));
        assert(BASS_ChannelSetPosition(mixerMaster, 0, BASS_POS_BYTE));
        
        // now previousInactiveStream == self.activeStream
        [self toggleActiveStream];

        [self stopAndResetInactiveStream];
        
        // don't set up next here, wait until current is downloaded
        // the new current might have already finished though #wifi
        //
        // in that case, retrigger the download complete event since it was last called
        // when the currently active stream was inactive and it did nothing
        if(self.activeStream.preloadFinished) {
            if(![self updateNextTrackIfNecessary]) {
                [self setupInactiveStreamWithNext];
            }
        }
    }
    else {
        // no inactive stream. nothing to do...
        // move into a paused state
        BASS_ChannelPause(mixerMaster);
        [self changeCurrentState:BassPlaybackStatePaused];
    }
    
    [self notifyDelegateThatTrackChanged:previouslyActiveGUID
                                 withURL:previouslyActiveURL];
}

/*
- (void)printStatus {
    [self printStatus:activeStreamIdx withTrackIndex:self.currentlyPlayingIdentifier];
    [self printStatus:activeStreamIdx == 0 ? 1 : 0 withTrackIndex:self.nextIdentifier];
    dbug(@" ");
}

- (void)printStatus:(NSInteger)streamIdx withTrackIndex:(NSInteger)idx {
    QWORD connected = BASS_StreamGetFilePosition(streams[streamIdx].stream, BASS_FILEPOS_CONNECTED);
    QWORD downloadedBytes = BASS_StreamGetFilePosition(streams[streamIdx].stream, BASS_FILEPOS_DOWNLOAD);
    QWORD totalBytes = BASS_StreamGetFilePosition(streams[streamIdx].stream, BASS_FILEPOS_SIZE);
    
    QWORD playedBytes = BASS_ChannelGetPosition(streams[streamIdx].stream, BASS_POS_BYTE);
    QWORD totalPlayableBytes = BASS_ChannelGetLength(streams[streamIdx].stream, BASS_POS_BYTE);
    
    double downloadPct = 1.0 * downloadedBytes / totalBytes;
    double playPct = 1.0 * playedBytes / totalPlayableBytes;
    
    dbug(@"[Stream: %lu %u, identifier: %lu] Connected: %llu. Download: %.3f%%. Playback: %.3f%%.\n", (unsigned long)streamIdx, streams[streamIdx], (long)idx, connected, downloadPct, playPct);
}
 */

#pragma mark - Properties

- (NSUUID *)currentlyPlayingIdentifier {
    return self.activeStream.identifier;
}

- (NSURL *)currentlyPlayingURL {
    return self.activeStream.url;
}

- (NSURL *)nextURL {
    return self.inactiveStream.url;
}

- (NSUUID *)nextIdentifier {
    return self.inactiveStream.identifier;
}

#pragma mark - Playback Control

- (BassPlaybackState)currentState {
    return _currentState = BASS_ChannelIsActive(mixerMaster);
}

- (void)changeCurrentState:(BassPlaybackState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        _currentState = state;
        [self.delegate BASSDownloadPlaybackStateChanged:state];
    });
}

- (NSTimeInterval)currentDuration {
    QWORD len = BASS_ChannelGetLength(self.activeStream.stream, BASS_POS_BYTE);
    
    if(len == -1) {
        return 0.0000001;
    }

    return BASS_ChannelBytes2Seconds(self.activeStream.stream, len + self.activeStream.channelOffset);
}

- (NSTimeInterval)elapsed {
    QWORD elapsedBytes = BASS_ChannelGetPosition(self.activeStream.stream, BASS_POS_BYTE);
    
    if(elapsedBytes == -1) {
        return 0.0;
    }
    
    return BASS_ChannelBytes2Seconds(self.activeStream.stream, elapsedBytes + self.activeStream.channelOffset);
}

- (void)next {
    [self ensureHasAudioSession];

    dispatch_async(queue, ^{
        if(isInactiveStreamUsed) {
            [self mixInNextTrack:self.activeStream.stream];
        }
    });
}

- (void)pause {
    dispatch_async(queue, ^{
        // no assert because it could fail if already paused
        if(BASS_ChannelPause(mixerMaster)) {
            [self changeCurrentState:BassPlaybackStatePaused];
        }
    });
}

- (void)ensureHasAudioSession {
    if(AVAudioSession.sharedInstance.isOtherAudioPlaying) {
        // needed to handle weird car bluetooth scenarios
        [self setupAudioSession: NO];
    }
}

- (void)resume {
    [self ensureHasAudioSession];
    
    dispatch_async(queue, ^{
        // no assert because it could fail if already playing
        // the NO for the second argument prevents the buffer from clearing
        if(BASS_ChannelPlay(mixerMaster, NO)) {
            [self changeCurrentState:BassPlaybackStatePlaying];
        }
    });
}

- (void)stop {
    dispatch_async(queue, ^{
        if(BASS_ChannelStop(mixerMaster)) {
            [self changeCurrentState:BassPlaybackStateStopped];
        }
    });
}

- (void)seekToPercent:(float)pct {
    dispatch_async(queue, ^{
        [self _seekToPercent:pct];
    });
}

- (void)_seekToPercent:(float)pct {
    // NOTE: all these calculations use the stream request offset to translate the #s into one's valid
    // for the *entire* track. we must be careful to identify situations where we need to make a new request
    
    QWORD len = BASS_ChannelGetLength(self.activeStream.stream, BASS_POS_BYTE) + self.activeStream.channelOffset;
    double duration = BASS_ChannelBytes2Seconds(self.activeStream.stream, len);
    QWORD seekTo = BASS_ChannelSeconds2Bytes(self.activeStream.stream, duration * pct);
    double seekToDuration = BASS_ChannelBytes2Seconds(self.activeStream.stream, seekTo);
    
    dbug(@"[bass][stream %lu] Found length in bytes to be %llu bytes/%f. Seeking to: %llu bytes/%f", (unsigned long)activeStreamIdx, len, duration, seekTo, seekToDuration);
    
    QWORD downloadedBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_DOWNLOAD) + self.activeStream.fileOffset;
    QWORD totalFileBytes = BASS_StreamGetFilePosition(self.activeStream.stream, BASS_FILEPOS_SIZE) + self.activeStream.fileOffset;
    double downloadedPct = 1.0 * downloadedBytes / totalFileBytes;
    
    BOOL seekingBeforeStartOfThisRequest = seekTo < self.activeStream.channelOffset;
    BOOL seekingBeyondDownloaded = pct > downloadedPct;
    
    // seeking before the offset point --> we need to make a new request
    // seeking after the most recently downloaded data --> we need to make a new request
    if(seekingBeforeStartOfThisRequest || seekingBeyondDownloaded) {
        DWORD fileOffset = (DWORD)floor(pct * totalFileBytes);

        dbug(@"[bass][stream %lu] Seek %% (%f/%u) is greater than downloaded %% (%f/%llu) OR seek channel byte (%llu) < start channel offset (%llu). Opening new stream.", (unsigned long)activeStreamIdx, pct, fileOffset, downloadedPct, downloadedBytes, seekTo, self.activeStream.channelOffset);
        
        HSTREAM oldActiveStream = self.activeStream.stream;
        
        if([self buildAndSetupActiveStreamForURL:self.currentlyPlayingURL
                                  withIdentifier:self.currentlyPlayingIdentifier
                                      fileOffset:fileOffset
                                andChannelOffset:seekTo] != 0) {
            assert(BASS_Mixer_StreamAddChannel(mixerMaster, self.activeStream.stream, BASS_STREAM_AUTOFREE | BASS_MIXER_NORAMPIN));
            
            // the TRUE for the second argument clears the buffer to prevent bits of the old playback
            assert(BASS_ChannelPlay(mixerMaster, TRUE));
            
            BASS_Mixer_ChannelRemove(oldActiveStream);
            BASS_ChannelStop(oldActiveStream);
        }
    }
    else {
        assert(BASS_ChannelSetPosition(self.activeStream.stream, seekTo - self.activeStream.channelOffset, BASS_POS_BYTE));
    }
}

- (float)volume {
    return BASS_GetVolume();
}

- (void)setVolume:(float)volume {
    BASS_SetVolume(volume);
}

#pragma mark - Error Helpers

- (NSError *)errorForErrorCode:(BassStreamError)erro {
    NSString *str;
    
    if(erro == BassStreamErrorInit)
        str = @"BASS_ERROR_INIT: BASS_Init has not been successfully called.";
    else if(erro == BassStreamErrorNotAvail)
        str = @"BASS_ERROR_NOTAVAIL: Only decoding channels (BASS_STREAM_DECODE) are allowed when using the \"no sound\" device. The BASS_STREAM_AUTOFREE flag is also unavailable to decoding channels.";
    else if(erro == BassStreamErrorNoInternet)
        str = @"BASS_ERROR_NONET: No internet connection could be opened. Can be caused by a bad proxy setting.";
    else if(erro == BassStreamErrorInvalidUrl)
        str = @"BASS_ERROR_ILLPARAM: url is not a valid URL.";
    else if(erro == BassStreamErrorSslUnsupported)
        str = @"BASS_ERROR_SSL: SSL/HTTPS support is not available.";
    else if(erro == BassStreamErrorServerTimeout)
        str = @"BASS_ERROR_TIMEOUT: The server did not respond to the request within the timeout period, as set with the BASS_CONFIG_NET_TIMEOUT config option.";
    else if(erro == BassStreamErrorCouldNotOpenFile)
        str = @"BASS_ERROR_FILEOPEN: The file could not be opened.";
    else if(erro == BassStreamErrorFileInvalidFormat)
        str = @"BASS_ERROR_FILEFORM: The file's format is not recognised/supported.";
    else if(erro == BassStreamErrorSupportedCodec)
        str = @"BASS_ERROR_CODEC: The file uses a codec that is not available/supported. This can apply to WAV and AIFF files, and also MP3 files when using the \"MP3-free\" BASS version.";
    else if(erro == BassStreamErrorUnsupportedSampleFormat)
        str = @"BASS_ERROR_SPEAKER: The sample format is not supported by the device/drivers. If the stream is more than stereo or the BASS_SAMPLE_FLOAT flag is used, it could be that they are not supported.";
    else if(erro == BassStreamErrorInsufficientMemory)
        str = @"BASS_ERROR_MEM: There is insufficient memory.";
    else if(erro == BassStreamErrorNo3D)
        str = @"BASS_ERROR_NO3D: Could not initialize 3D support.";
    else if(erro == BassStreamErrorUnknown)
        str = @"BASS_ERROR_UNKNOWN: Some other mystery problem! Usually this is when the Internet is available but the server/port at the specific URL isn't.";
    
    return [NSError errorWithDomain:@"com.alecgorge.ios.objectivebass"
                               code:erro
                           userInfo:@{NSLocalizedDescriptionKey: str}];
}

#pragma mark - Audio Session Routing/Interruption Handling

- (void)setupAudioSession:(BOOL)addObservers {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionAllowAirPlay | AVAudioSessionCategoryOptionAllowBluetooth
                   error:nil];
    
    [session setActive:YES
                 error:nil];
    
    if(!audioSessionAlreadySetUp) {
        // Register for Route Change notifications
        if(addObservers) {
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(handleRouteChange:)
                                                       name:AVAudioSessionRouteChangeNotification
                                                     object:session];
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(handleInterruption:)
                                                       name:AVAudioSessionInterruptionNotification
                                                     object:session];
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(handleMediaServicesWereReset:)
                                                       name:AVAudioSessionMediaServicesWereResetNotification
                                                     object:session];
        }
        
        if([self.delegate respondsToSelector:@selector(BASSAudioSessionSetUp)]) {
            [self.delegate BASSAudioSessionSetUp];
        }
        
        audioSessionAlreadySetUp = YES;
    }
}

- (void)teardownAudioSession {
    [AVAudioSession.sharedInstance setActive:NO
                                       error:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"AVAudioSessionRouteChangeNotification" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"AVAudioSessionInterruptionNotification" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"AVAudioSessionMediaServicesWereResetNotification" object:nil];
}

- (void)handleMediaServicesWereReset:(NSNotification*)notification{
    //  If the media server resets for any reason, handle this notification to reconfigure audio or do any housekeeping, if necessary
    //    • No userInfo dictionary for this notification
    //      • Audio streaming objects are invalidated (zombies)
    //      • Handle this notification by fully reconfiguring audio
    dbug(@"handleMediaServicesWereReset: %@ ",[notification name]);
}

- (void)handleInterruption:(NSNotification*)notification{
    NSInteger reason = 0;
    NSString* reasonStr=@"";
    if ([notification.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
        // Posted when an audio interruption occurs.
        
        reason = [[notification.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            // Audio has stopped, already inactive
            // Change state of UI, etc., to reflect non-playing state
            wasPlayingWhenInterrupted = self.currentState == BassPlaybackStatePlaying || self.currentState == BassPlaybackStateStalled;
            
            [self pause];
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            // Make session active
            // Update user interface
            // AVAudioSessionInterruptionOptionShouldResume option
            
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            
            NSNumber* seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            
            switch (seccondReason.integerValue) {
                case AVAudioSessionInterruptionOptionShouldResume:
                    // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    if(wasPlayingWhenInterrupted) {
                        [self resume];
                    }
                    break;
                default:
                    break;
            }
        }
        
        /*
        if ([notification.name isEqualToString:@"AVAudioSessionDidBeginInterruptionNotification"]) {
            if (soundSessionIO_.isProcessingSound) {
                
            }
            //      Posted after an interruption in your audio session occurs.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionDidEndInterruptionNotification"]) {
            //      Posted after an interruption in your audio session ends.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeAvailableNotification"]) {
            //      Posted when an input to the audio session becomes available.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeUnavailableNotification"]) {
            //      Posted when an input to the audio session becomes unavailable.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        */
    }
    
    dbug(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

-(void)handleRouteChange:(NSNotification*)notification{
    NSString* seccReason = nil;
    NSInteger reason = [[notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            [self pause];
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    
    dbug(@"handlRouteChange: %@", seccReason);
}

@end

