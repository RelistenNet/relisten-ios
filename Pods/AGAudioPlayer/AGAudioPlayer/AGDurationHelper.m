//
//  AGDurationHelper.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/13/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGDurationHelper.h"

@implementation AGDurationHelper

+ (NSString *)generalizeStringWithInterval:(NSTimeInterval)interval {
	NSString *retVal = @"At time of event";
	if (interval == 0) return retVal;
	
	int second = 1;
	int minute = second * 60;
	int hour = minute * 60;
	
	// interval can be before (negative) or after (positive)
	int num = abs(interval);
	
	NSString *unit = @"hours";
	
	if (num >= hour) {
		num /= hour;
		unit = (num > 1) ? @"hours" : @"hour";
	} else if (num >= minute) {
		num /= minute;
		unit = (num > 1) ? @"minutes" : @"minute";
	} else if (num >= second) {
		num /= second;
		unit = (num > 1) ? @"seconds" : @"second";
	}
	
	return [NSString stringWithFormat:@"%d %@", num, unit];
}

+ (NSString *)formattedTimeWithInterval:(NSTimeInterval)interval {
	NSInteger ti = (NSInteger)interval;
	NSInteger seconds = ti % 60;
	NSInteger minutes = (ti / 60) % 60;
	NSInteger hours = (ti / 3600);
	
	if(hours == 0) {
		return [NSString stringWithFormat:@"%li:%02li", (long)minutes, (long)seconds];
	}
	
	return [NSString stringWithFormat:@"%li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
}

@end
