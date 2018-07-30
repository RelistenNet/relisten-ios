//
//  RelistenAlbumArtCache.h
//  PhishOD
//
//  Created by Alec Gorge on 10/7/15.
//  Copyright © 2015 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FastImageCache/FICImageCache.h>

static NSString *RelistenImageFormatSmall = @"net.relisten.ios.albumart.small";
static NSString *RelistenImageFormatMedium = @"net.relisten.ios.phishod.albumart.medium";
static NSString *RelistenImageFormatFull = @"net.relisten.ios.phishod.albumart.full";
static NSString *RelistenImageFamily = @"net.relisten.ios.phishod.albumart";

@interface RelistenAlbumArtCache : NSObject <FICImageCacheDelegate>

+(instancetype)sharedInstance;

@property (nonatomic, readonly) FICImageCache *sharedCache;

@end
