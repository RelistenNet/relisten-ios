//
//  RelistenAlbumArtCache.h
//  PhishOD
//
//  Created by Alec Gorge on 10/7/15.
//  Copyright © 2015 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FastImageCache/FICImageCache.h>

static NSString *PHODImageFormatSmall = @"com.alecgorge.ios.phishod.albumart.small";
static NSString *PHODImageFormatMedium = @"com.alecgorge.ios.phishod.albumart.medium";
static NSString *PHODImageFormatFull = @"com.alecgorge.ios.phishod.albumart.full";
static NSString *PHODImageFamily = @"com.alecgorge.ios.phishod.albumart";

@interface RelistenAlbumArtCache : NSObject <FICImageCacheDelegate>

+(instancetype)sharedInstance;

@property (nonatomic, readonly) FICImageCache *sharedCache;

@end
