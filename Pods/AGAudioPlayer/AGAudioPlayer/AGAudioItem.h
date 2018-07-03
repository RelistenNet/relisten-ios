//
//  AGAudioItem.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AGAudioItemCollection.h"

@class MPMediaItemArtwork;

@interface AGAudioItem : NSObject

@property (nonatomic, readonly) NSUUID * _Nonnull playbackGUID;

@property (nonatomic) AGAudioItemCollection * _Nullable collection;

@property (nonatomic) NSInteger id;

@property (nonatomic) NSInteger trackNumber;
@property (nonatomic) NSString * _Nonnull title;
@property (nonatomic) NSString * _Nonnull artist;
@property (nonatomic) NSString * _Nonnull album;

@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) NSString * _Nonnull displayText;
@property (nonatomic) NSString * _Nonnull displaySubtext;

@property (nonatomic) NSURL * _Nullable albumArt;
@property (nonatomic) NSURL * _Nonnull playbackURL;
// @property (nonatomic) NSDictionary *playbackRequestHTTPHeaders;

@property (nonatomic, readonly) MPMediaItemArtwork * _Nullable artwork;

@property (nonatomic) BOOL metadataLoaded;

// this should only load new metadata if it isn't loaded yet or it needs to be updated
- (void)loadMetadata:(nonnull void (^)(AGAudioItem * _Nonnull))metadataCallback;

- (void)shareText:(nonnull void(^)(NSString * _Nonnull))stringBuilt;
- (void)shareURL:(nonnull void(^)(NSURL * _Nonnull))urlFound;

- (void)shareURLWithTime:(NSTimeInterval)shareTime
				callback:(nonnull void(^)(NSURL * _Nonnull))urlFound;

@end
