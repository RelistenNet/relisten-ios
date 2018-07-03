//
//  AGAudioItemCollection.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import "AGAudioItemCollection.h"

@implementation AGAudioItemCollection

- (instancetype)initWithItems:(NSArray *)items {
	if (self = [super init]) {
		self.items = items;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.displayText	= [aDecoder decodeObjectForKey:@"displayText"];
		self.displaySubtext = [aDecoder decodeObjectForKey:@"displaySubtext"];
		self.albumArt		= [aDecoder decodeObjectForKey:@"albumArt"];
		self.items      	= [aDecoder decodeObjectForKey:@"items"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.displayText
				  forKey:@"displayText"];
	
	[aCoder encodeObject:self.displaySubtext
				  forKey:@"displaySubtext"];
	
	[aCoder encodeObject:self.albumArt
				  forKey:@"albumArt"];
	
	[aCoder encodeObject:self.items
				  forKey:@"items"];
}

- (NSString *)cacheKey {
	return [NSString stringWithFormat:@"%@,%@", self.displayText, self.displaySubtext];
}

@end
