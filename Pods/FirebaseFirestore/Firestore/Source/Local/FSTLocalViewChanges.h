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

#import "Firestore/Source/Model/FSTDocumentKeySet.h"

@class FSTDocumentSet;
@class FSTMutation;
@class FSTQuery;
@class FSTRemoteEvent;
@class FSTViewSnapshot;

NS_ASSUME_NONNULL_BEGIN

/**
 * A set of changes to what documents are currently in view and out of view for a given query.
 * These changes are sent to the LocalStore by the View (via the SyncEngine) and are used to pin /
 * unpin documents as appropriate.
 */
@interface FSTLocalViewChanges : NSObject

+ (instancetype)changesForQuery:(FSTQuery *)query
                      addedKeys:(FSTDocumentKeySet *)addedKeys
                    removedKeys:(FSTDocumentKeySet *)removedKeys;

+ (instancetype)changesForViewSnapshot:(FSTViewSnapshot *)viewSnapshot;

- (id)init NS_UNAVAILABLE;

@property(nonatomic, strong, readonly) FSTQuery *query;
@property(nonatomic, strong) FSTDocumentKeySet *addedKeys;
@property(nonatomic, strong) FSTDocumentKeySet *removedKeys;

@end

NS_ASSUME_NONNULL_END
