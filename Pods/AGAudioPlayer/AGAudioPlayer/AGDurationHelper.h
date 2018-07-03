//
//  AGDurationHelper.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/13/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGDurationHelper : NSObject

+ (NSString *)generalizeStringWithInterval:(NSTimeInterval)interval;
+ (NSString *)formattedTimeWithInterval:(NSTimeInterval)interval;

@end
