/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "Firestore/Source/Core/FSTTypes.h"
#import "Firestore/Source/Model/FSTDocumentDictionary.h"
#import "Firestore/Source/Model/FSTDocumentKeySet.h"

#include "Firestore/core/src/firebase/firestore/model/document_key.h"

@class FSTDocumentSet;
@class FSTDocumentViewChangeSet;
@class FSTMaybeDocument;
@class FSTQuery;
@class FSTTargetChange;
@class FSTViewSnapshot;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FSTViewDocumentChanges

/** The result of applying a set of doc changes to a view. */
@interface FSTViewDocumentChanges : NSObject

- (instancetype)init NS_UNAVAILABLE;

/** The new set of docs that should be in the view. */
@property(nonatomic, strong, readonly) FSTDocumentSet *documentSet;

/** The diff of this these docs with the previous set of docs. */
@property(nonatomic, strong, readonly) FSTDocumentViewChangeSet *changeSet;

/**
 * Whether the set of documents passed in was not sufficient to calculate the new state of the view
 * and there needs to be another pass based on the local cache.
 */
@property(nonatomic, assign, readonly) BOOL needsRefill;

@property(nonatomic, strong, readonly) FSTDocumentKeySet *mutatedKeys;

@end

#pragma mark - FSTLimboDocumentChange

typedef NS_ENUM(NSInteger, FSTLimboDocumentChangeType) {
  FSTLimboDocumentChangeTypeAdded = 0,
  FSTLimboDocumentChangeTypeRemoved,
};

// A change to a particular document wrt to whether it is in "limbo".
@interface FSTLimboDocumentChange : NSObject

+ (instancetype)changeWithType:(FSTLimboDocumentChangeType)type
                           key:(firebase::firestore::model::DocumentKey)key;

- (id)init __attribute__((unavailable("Use a static constructor method.")));

- (const firebase::firestore::model::DocumentKey &)key;

@property(nonatomic, assign, readonly) FSTLimboDocumentChangeType type;
@end

#pragma mark - FSTViewChange

// A set of changes to a view.
@interface FSTViewChange : NSObject

- (id)init __attribute__((unavailable("Use a static constructor method.")));

@property(nonatomic, strong, readonly, nullable) FSTViewSnapshot *snapshot;
@property(nonatomic, strong, readonly) NSArray<FSTLimboDocumentChange *> *limboChanges;
@end

#pragma mark - FSTView

/**
 * View is responsible for computing the final merged truth of what docs are in a query. It gets
 * notified of local and remote changes to docs, and applies the query filters and limits to
 * determine the most correct possible results.
 */
@interface FSTView : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithQuery:(FSTQuery *)query
              remoteDocuments:(FSTDocumentKeySet *)remoteDocuments NS_DESIGNATED_INITIALIZER;

/**
 * Iterates over a set of doc changes, applies the query limit, and computes what the new results
 * should be, what the changes were, and whether we may need to go back to the local cache for
 * more results. Does not make any changes to the view.
 *
 * @param docChanges The doc changes to apply to this view.
 * @return a new set of docs, changes, and refill flag.
 */
- (FSTViewDocumentChanges *)computeChangesWithDocuments:(FSTMaybeDocumentDictionary *)docChanges;

/**
 * Iterates over a set of doc changes, applies the query limit, and computes what the new results
 * should be, what the changes were, and whether we may need to go back to the local cache for
 * more results. Does not make any changes to the view.
 *
 * @param docChanges The doc changes to apply to this view.
 * @param previousChanges If this is being called with a refill, then start with this set of docs
 *     and changes instead of the current view.
 * @return a new set of docs, changes, and refill flag.
 */
- (FSTViewDocumentChanges *)computeChangesWithDocuments:(FSTMaybeDocumentDictionary *)docChanges
                                        previousChanges:
                                            (nullable FSTViewDocumentChanges *)previousChanges;

/**
 * Updates the view with the given ViewDocumentChanges.
 *
 * @param docChanges The set of changes to make to the view's docs.
 * @return A new FSTViewChange with the given docs, changes, and sync state.
 */
- (FSTViewChange *)applyChangesToDocuments:(FSTViewDocumentChanges *)docChanges;

/**
 * Updates the view with the given FSTViewDocumentChanges and updates limbo docs and sync state from
 * the given (optional) target change.
 *
 * @param docChanges The set of changes to make to the view's docs.
 * @param targetChange A target change to apply for computing limbo docs and sync state.
 * @return A new FSTViewChange with the given docs, changes, and sync state.
 */
- (FSTViewChange *)applyChangesToDocuments:(FSTViewDocumentChanges *)docChanges
                              targetChange:(nullable FSTTargetChange *)targetChange;

/**
 * Applies an FSTOnlineState change to the view, potentially generating an FSTViewChange if the
 * view's syncState changes as a result.
 */
- (FSTViewChange *)applyChangedOnlineState:(FSTOnlineState)onlineState;

/**
 * The set of remote documents that the server has told us belongs to the target associated with
 * this view.
 */
@property(nonatomic, strong, readonly) FSTDocumentKeySet *syncedDocuments;

@end

NS_ASSUME_NONNULL_END
