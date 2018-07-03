//
//  AGAudioPlayerUpNextQueue.m
//  AGAudioPlayer
//
//  Created by Alec Gorge on 12/19/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "AGAudioPlayerUpNextQueue.h"

@interface AGAudioPlayerUpNextQueue ()

@property (nonatomic) NSMutableArray<AGAudioItem *> *items;
@property (nonatomic) NSMutableArray<AGAudioItem *> *shuffledItems;

@end

@implementation AGAudioPlayerUpNextQueue

- (id)init {
    if (self = [super init]) {
        self.items = NSMutableArray.array;
        self.shuffledItems = NSMutableArray.array;
    }
    return self;
}

- (instancetype)initWithItems:(NSArray *)items {
    if (self = [super init]) {
        self.items = NSMutableArray.array;
        self.shuffledItems = NSMutableArray.array;
        
        [self appendItems:items];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.items = NSMutableArray.array;
        
        [self appendItems:[aDecoder decodeObjectForKey:@"items"]];
        
        for (AGAudioItem * item in self.items) {
            [self.shuffledItems insertObject:item
                                     atIndex:arc4random_uniform((u_int32_t)self.items.count)];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.items forKey:@"items"];
}

- (NSInteger)count {
    return self.items.count;
}

- (void)appendItem:(AGAudioItem *)item {
    [self appendItem:item sendNotice:YES];
}

- (void)appendItem:(AGAudioItem *)item sendNotice:(BOOL)sendNotice {
    if(item == nil) return;
    
    [self.items addObject:item];
    
    [self.shuffledItems insertObject:item
                             atIndex:arc4random_uniform((u_int32_t)self.items.count)];
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueAddedItem];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueue:addedItem:atIndex:)]) {
        [self.delegate upNextQueue:self
                         addedItem:item
                           atIndex:self.items.count - 1];
    }
}

- (void)appendItems:(NSArray<AGAudioItem *> * _Nonnull)items sendNotice:(BOOL)sendNotice {
    for (AGAudioItem * i in items) {
        [self appendItem:i sendNotice:NO];
    }

    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueAddedItems];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueue:addedItems:atIndex:)]) {
        [self.delegate upNextQueue:self
                        addedItems:items
                           atIndex:self.items.count - items.count];
    }
}

- (void)appendItems:(NSArray<AGAudioItem *> * _Nonnull)items {
    [self appendItems:items sendNotice:YES];
}

- (void)prependItem:(AGAudioItem *)item {
    [self prependItem:item sendNotice:YES];
}

- (void)prependItem:(AGAudioItem *)item sendNotice:(BOOL)sendNotice {
    if(item == nil) return;
    
    [self.items insertObject:item
                     atIndex:0];
    
    [self.shuffledItems insertObject:item
                             atIndex:arc4random_uniform((u_int32_t)self.items.count)];
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueAddedItem];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueue:addedItem:atIndex:)]) {
        [self.delegate upNextQueue:self
                         addedItem:item
                           atIndex:0];
    }
}

- (void)prependItems:(NSArray *)items {
    [self prependItems:items sendNotice:YES];
}

- (void)prependItems:(NSArray *)items sendNotice:(BOOL)sendNotice {
    for (AGAudioItem * i in items) {
        [self prependItem:i sendNotice:NO];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueAddedItems];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueue:addedItems:atIndex:)]) {
        [self.delegate upNextQueue:self
                        addedItems:items
                           atIndex:self.items.count - items.count];
    }
}

- (void)insertItem:(AGAudioItem *)item atIndex: (NSUInteger)idx {
    [self.items insertObject:item atIndex:idx];
    [self.shuffledItems insertObject:item atIndex:arc4random_uniform((u_int32_t)self.items.count)];

    if([self.delegate respondsToSelector:@selector(upNextQueue:addedItem:atIndex:)]) {
        [self.delegate upNextQueue:self
                         addedItem:item
                           atIndex:idx];
    }
}

- (void)moveItem:(AGAudioItem *)item
         toIndex:(NSInteger)to {
    NSInteger from = [self.items indexOfObjectIdenticalTo:item];
    [self moveItemAtIndex:from
                  toIndex:to];
}

- (void)moveItemAtIndex:(NSInteger)from toIndex:(NSInteger)to {
    id object = [self.items objectAtIndex:from];
    [self.items removeObjectAtIndex:from];
    [self.items insertObject:object atIndex:to];
    
    // 0 length and 1 length cause an infinite loop
    // swap two items randomly
    if(self.items.count > 1) {
        u_int32_t shuffle_from = arc4random_uniform((u_int32_t)self.items.count);
        u_int32_t shuffle_to = UINT32_MAX;
        
        while((shuffle_to = arc4random_uniform((u_int32_t)self.items.count)) == shuffle_from);
        
        id obj = [self.items objectAtIndex:shuffle_from];
        [self.shuffledItems removeObjectAtIndex:shuffle_from];
        [self.shuffledItems insertObject:obj atIndex:to];
    }
    
    if([self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueSwappedItems];
    }
    
    if([self.delegate respondsToSelector:@selector(upNextQueue:movedItem:fromIndex:toIndex:)]) {
        [self.delegate upNextQueue:self
                         movedItem:self.items[to] // swap has already taken place so use flipped indices
                         fromIndex:from
                           toIndex:to];
    }
}

- (void)clear:(BOOL)sendNotice {
    if(self.items.count == 0) {
        return;
    }
    
    [self.items removeAllObjects];
    [self.shuffledItems removeAllObjects];
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueRemovedAllItems];
    }
    
    if(sendNotice && [self.delegate respondsToSelector:@selector(upNextQueueRemovedAllItems:)]) {
        [self.delegate upNextQueueRemovedAllItems:self];
    }
}

- (void)clear {
    [self clear:YES];
}

- (void)clearAndReplaceWithItems:(NSArray *)items {
    [self clear:NO];
    [self appendItems:items sendNotice:NO];
    
    if([self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueReplacedAllItems];
    }
    
    if([self.delegate respondsToSelector:@selector(upNextQueueReplacedAllItems:)]) {
        [self.delegate upNextQueueReplacedAllItems:self];
    }
}

- (void)removeItem:(AGAudioItem *)item {
    if(item == nil) return;
    
    NSInteger idx = [self.items indexOfObjectIdenticalTo:item];
    
    if(idx == NSNotFound) return;
    
    [self removeItemAtIndex:idx];
}

- (void)removeItemAtIndex:(NSInteger)indx {
    AGAudioItem * old_value = self.items[indx];
    [self.items removeObjectAtIndex:indx];
    
    // not by
    [self.shuffledItems removeObject:old_value];
    
    if([self.delegate respondsToSelector:@selector(upNextQueueChanged:)]) {
        [self.delegate upNextQueueChanged:AGAudioPlayerUpNextQueueRemovedItem];
    }
    
    if([self.delegate respondsToSelector:@selector(upNextQueue:removedItem:fromIndex:)]) {
        [self.delegate upNextQueue:self
                       removedItem:old_value
                         fromIndex:indx];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.items[idx];
}

- (AGAudioItem *)shuffledItemAtIndex:(NSUInteger)idx {
    return self.shuffledItems[idx];
}

- (AGAudioItem *)unshuffledItemAtIndex:(NSUInteger)idx {
    return self.items[idx];
}

- (NSArray *)queue {
    return self.items;
}

- (NSArray *)shuffledQueue {
    return self.shuffledItems;
}

- (NSArray<AGAudioItem *> *)properQueueForShuffleEnabled:(BOOL)shuffleEnabled {
    if (shuffleEnabled) {
        return self.shuffledItems;
    }
    
    return self.items;
}

- (NSUInteger)indexOfURL:(NSURL *)url {
    for(NSInteger i = 0; i < self.count; i++) {
        if ([[[self unshuffledItemAtIndex:i] playbackURL] isEqual:url]) {
            return i;
        }
    }
    return 0;
}

- (AGAudioItem *)itemForId:(nonnull NSUUID *)_id {
    for (AGAudioItem * item in self.items) {
        if([item.playbackGUID isEqual:_id]) {
            return item;
        }
    }
    
    return nil;
}

- (NSInteger)properPositionForId:(nonnull NSUUID *)_id
               forShuffleEnabled:(BOOL)shuffleEnabled {
    NSArray<AGAudioItem *> *items = [self properQueueForShuffleEnabled:shuffleEnabled];
    for(NSInteger i = 0; i < self.count; i++) {
        if ([items[i].playbackGUID isEqual:_id]) {
            return i;
        }
    }
    
    return NSNotFound;
}

- (void)shuffleStartingAtIndex:(NSUInteger)idx {
    AGAudioItem *starter = self.items[idx];
    self.shuffledItems = NSMutableArray.array;
    
    for (AGAudioItem *item in self.items) {
        if(starter == item) {
            continue;
        }
        
        if(self.shuffledItems.count == 0) {
            [self.shuffledItems addObject:item];
            continue;
        }
        
        [self.shuffledItems insertObject:item
                                 atIndex:arc4random_uniform((u_int32_t)self.shuffledItems.count)];
    }
    
    [self.shuffledItems insertObject:starter
                             atIndex:0];
}

@end
