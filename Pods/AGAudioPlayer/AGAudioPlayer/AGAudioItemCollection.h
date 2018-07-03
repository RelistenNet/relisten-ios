//
//  AGAudioItemCollection.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 3/15/15.
//  Copyright (c) 2015 Alec Gorge. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGAudioItem;

@interface AGAudioItemCollection : NSObject<NSCoding>

@property (nonatomic) NSString * _Nonnull displayText;
@property (nonatomic) NSString * _Nonnull displaySubtext;
@property (nonatomic) NSURL * _Nullable albumArt;

@property (nonatomic) NSArray * _Nonnull items;

- (_Nonnull instancetype)initWithItems:(NSArray<AGAudioItem *> * _Nonnull) items;

@end
