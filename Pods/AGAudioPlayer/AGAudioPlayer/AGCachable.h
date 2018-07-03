//
//  AGCachable.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

@protocol AGCachable <NSCoding>

@property (nonatomic, readonly) NSString *cacheKey;
@property (nonatomic, readonly) BOOL isCached;

@end
