//
//  AGAudioPlayerUpNextQueue.h
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <Foundation/NSEnumerator.h>

#import "AGAudioItem.h"

typedef NS_ENUM(NSInteger, AGAudioPlayerUpNextQueueChanged) {
    AGAudioPlayerUpNextQueueAddedItem,
    AGAudioPlayerUpNextQueueRemovedItem,
    AGAudioPlayerUpNextQueueRemovedAllItems,
    AGAudioPlayerUpNextQueueSwappedItems,
    AGAudioPlayerUpNextQueueChangedItem,
    AGAudioPlayerUpNextQueueReplacedAllItems,
    AGAudioPlayerUpNextQueueAddedItems,
};

@class AGAudioPlayerUpNextQueue;

@protocol AGAudioPlayerUpNextQueueDelegate <NSObject>

@optional

- (void)upNextQueueChanged:(AGAudioPlayerUpNextQueueChanged)changeType;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue * _Nonnull)queue
          addedItem:(AGAudioItem * _Nonnull)item
            atIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue * _Nonnull)queue
         addedItems:(NSArray<AGAudioItem *> * _Nonnull)items
            atIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue * _Nonnull)queue
        removedItem:(AGAudioItem * _Nonnull)item
          fromIndex:(NSInteger)idx;

- (void)upNextQueue:(AGAudioPlayerUpNextQueue * _Nonnull)queue
          movedItem:(AGAudioItem * _Nonnull)item
          fromIndex:(NSInteger)oldIndex
            toIndex:(NSInteger)newIndex;

- (void)upNextQueueRemovedAllItems:(AGAudioPlayerUpNextQueue * _Nonnull)queue;

- (void)upNextQueueReplacedAllItems:(AGAudioPlayerUpNextQueue * _Nonnull)queue;

@end

@interface AGAudioPlayerUpNextQueue : NSObject<NSCoding>

- (_Nonnull instancetype)initWithItems:(NSArray<AGAudioItem *> * _Nonnull)items;

@property (nonatomic, weak) _Nullable id<AGAudioPlayerUpNextQueueDelegate> delegate;

@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, readonly)  NSArray<AGAudioItem *> * _Nonnull queue;
@property (nonatomic, readonly)  NSArray<AGAudioItem *> * _Nonnull shuffledQueue;

- (void)appendItem:(AGAudioItem * _Nonnull)item;
- (void)appendItems:(NSArray<AGAudioItem *> * _Nonnull)items;

- (void)prependItem:(AGAudioItem * _Nonnull)item;
- (void)prependItems:(NSArray<AGAudioItem *> * _Nonnull)items;

- (void)insertItem:(AGAudioItem * _Nonnull)item atIndex: (NSUInteger)idx;

- (void)moveItem:(AGAudioItem * _Nonnull)item
         toIndex:(NSInteger)to;

- (void)moveItemAtIndex:(NSInteger)from
                toIndex:(NSInteger)to;

- (void)clear;

- (void)clearAndReplaceWithItems:(NSArray<AGAudioItem *> * _Nonnull)items;

- (void)removeItem:(AGAudioItem * _Nonnull)item;
- (void)removeItemAtIndex:(NSInteger)indx;

- (AGAudioItem * _Nonnull)objectAtIndexedSubscript:(NSUInteger)idx;

- (AGAudioItem * _Nonnull)shuffledItemAtIndex:(NSUInteger)idx;
- (AGAudioItem * _Nonnull)unshuffledItemAtIndex:(NSUInteger)idx;

- (NSArray<AGAudioItem *> * _Nonnull)properQueueForShuffleEnabled:(BOOL)shuffleEnabled;

- (NSUInteger)indexOfURL:(NSURL * _Nonnull)url;

- (AGAudioItem * _Nonnull)itemForId:(nonnull NSUUID *)_id;

- (NSInteger)properPositionForId:(nonnull NSUUID *)_id
               forShuffleEnabled:(BOOL)shuffleEnabled;

- (void)shuffleStartingAtIndex:(NSUInteger)idx;

@end
