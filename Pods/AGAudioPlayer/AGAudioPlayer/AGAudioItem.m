//
//  AGAudioItem.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioItem.h"

@implementation AGAudioItem

- (instancetype)init {
    if (self = [super init]) {
        _playbackGUID = NSUUID.UUID;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
        _playbackGUID       = [aDecoder decodeObjectForKey:@"guid"];
        self.id             = [aDecoder decodeIntegerForKey:@"id"];
        self.trackNumber	= [aDecoder decodeIntegerForKey:@"trackNumber"];
		self.title			= [aDecoder decodeObjectForKey:@"title"];
		self.artist			= [aDecoder decodeObjectForKey:@"artist"];
		self.album			= [aDecoder decodeObjectForKey:@"album"];
		self.duration		= [aDecoder decodeDoubleForKey:@"duration"];
		self.displayText	= [aDecoder decodeObjectForKey:@"displayText"];
		self.displaySubtext = [aDecoder decodeObjectForKey:@"displaySubtext"];
        self.albumArt		= [aDecoder decodeObjectForKey:@"albumArt"];
        self.playbackURL	= [aDecoder decodeObjectForKey:@"playbackURL"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.trackNumber
                   forKey:@"trackNumber"];
    
    [aCoder encodeInteger:self.id
                   forKey:@"id"];
    
	[aCoder encodeObject:self.title
				  forKey:@"title"];
	
	[aCoder encodeObject:self.artist
				  forKey:@"artist"];
	
	[aCoder encodeObject:self.album
				  forKey:@"album"];
	
	[aCoder encodeDouble:self.duration
				  forKey:@"duration"];
	
	[aCoder encodeObject:self.displayText
				  forKey:@"displayText"];
	
	[aCoder encodeObject:self.displaySubtext
				  forKey:@"displaySubtext"];
    
    [aCoder encodeObject:self.albumArt
                  forKey:@"albumArt"];
    
    [aCoder encodeObject:self.playbackURL
                  forKey:@"playbackURL"];
    
    [aCoder encodeObject:self.playbackGUID
                  forKey:@"guid"];
}

- (BOOL)metadataLoaded {
	return YES;
}

- (void)loadMetadata:(void (^)(AGAudioItem *))metadataCallback {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareText:(void (^)(NSString *))stringBuilt {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareURL:(void (^)(NSURL *))urlFound {
	NSAssert(NO, @"This method must be overriden");
}

- (void)shareURLWithTime:(NSTimeInterval)shareTime
				callback:(void (^)(NSURL *))urlFound {
	NSAssert(NO, @"This method must be overriden");
}

- (NSUInteger)hash {
    if (self.playbackURL) {
        return self.playbackURL.hash;
    }
    
    return [NSString stringWithFormat:@"%d%@%@%@", (int)self.trackNumber, self.title, self.artist, self.album].hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - #%d - %@ - %@ - %@", self.playbackGUID.UUIDString, (int)self.trackNumber, self.title, self.artist, self.album];
}

@end
