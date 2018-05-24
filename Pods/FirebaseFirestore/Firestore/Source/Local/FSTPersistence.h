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

#import "Firestore/Source/Util/FSTAssert.h"
#include "Firestore/core/src/firebase/firestore/auth/user.h"

@protocol FSTMutationQueue;
@protocol FSTQueryCache;
@protocol FSTRemoteDocumentCache;

NS_ASSUME_NONNULL_BEGIN

/**
 * FSTPersistence is the lowest-level shared interface to persistent storage in Firestore.
 *
 * FSTPersistence is used to create FSTMutationQueue and FSTRemoteDocumentCache instances backed
 * by persistence (which might be in-memory or LevelDB).
 *
 * FSTPersistence also exposes an API to create and commit FSTWriteGroup instances.
 * Implementations of FSTWriteGroup/FSTPersistence only need to guarantee that writes made
 * against the FSTWriteGroup are not made to durable storage until commitGroup:action: is called
 * here. Since memory-only storage components do not alter durable storage, they are free to ignore
 * the group.
 *
 * This contract is enough to allow the FSTLocalStore be be written independently of whether or not
 * the stored state actually is durably persisted. If persistent storage is enabled, writes are
 * grouped together to avoid inconsistent state that could cause crashes.
 *
 * Concretely, when persistent storage is enabled, the persistent versions of FSTMutationQueue,
 * FSTRemoteDocumentCache, and others (the mutators) will defer their writes into an FSTWriteGroup.
 * Once the local store has completed one logical operation, it commits the write group using
 * [FSTPersistence commitGroup:action:].
 *
 * When persistent storage is disabled, the non-persistent versions of the mutators ignore the
 * FSTWriteGroup and [FSTPersistence commitGroup:action:] is a no-op. This short-cut is allowed
 * because memory-only storage leaves no state so it cannot be inconsistent.
 *
 * This simplifies the implementations of the mutators and allows memory-only implementations to
 * supplement the persistent ones without requiring any special dual-store implementation of
 * FSTPersistence. The cost is that the FSTLocalStore needs to be slightly careful about the order
 * of its reads and writes in order to avoid relying on being able to read back uncommitted writes.
 */
struct FSTTransactionRunner;
@protocol FSTPersistence <NSObject>

/**
 * Starts persistent storage, opening the database or similar.
 *
 * @param error An error object that will be populated if startup fails.
 * @return YES if persistent storage started successfully, NO otherwise.
 */
- (BOOL)start:(NSError **)error;

/** Releases any resources held during eager shutdown. */
- (void)shutdown;

/**
 * Returns an FSTMutationQueue representing the persisted mutations for the given user.
 *
 * <p>Note: The implementation is free to return the same instance every time this is called for a
 * given user. In particular, the memory-backed implementation does this to emulate the persisted
 * implementation to the extent possible (e.g. in the case of uid switching from
 * sally=>jack=>sally, sally's mutation queue will be preserved).
 */
- (id<FSTMutationQueue>)mutationQueueForUser:(const firebase::firestore::auth::User &)user;

/** Creates an FSTQueryCache representing the persisted cache of queries. */
- (id<FSTQueryCache>)queryCache;

/** Creates an FSTRemoteDocumentCache representing the persisted cache of remote documents. */
- (id<FSTRemoteDocumentCache>)remoteDocumentCache;

@property(nonatomic, readonly, assign) const FSTTransactionRunner &run;

@end

@protocol FSTTransactional

- (void)startTransaction:(absl::string_view)label;

- (void)commitTransaction;

@end

struct FSTTransactionRunner {
// Intentionally disable nullability checking for this function. We cannot properly annotate
// the function because this function can handle both pointer and non-pointer types. It is an error
// to annotate non-pointer types with a nullability annotation.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

  /**
   * The following two functions handle accepting callables and optionally running them within a
   * transaction. Persistence layers that conform to the FSTTransactional protocol can set
   * themselves as the backing persistence for a transaction runner, in which case a transaction
   * will be started before a block is run, and committed after the block has executed. If there is
   * no backing instance of FSTTransactional, the block will be run directly.
   *
   * There are two instances of operator() to handle the case where the block returns void, rather
   * than a type.
   *
   * The transaction runner keeps a weak reference to the backing persistence so as not to cause a
   * retain cycle. The reference is upgraded to strong (with a fatal error if it has disappeared)
   * for the duration of running a transaction.
   */

  template <typename F>
  auto operator()(absl::string_view label, F block) const ->
      typename std::enable_if<std::is_void<decltype(block())>::value, void>::type {
    __strong id<FSTTransactional> strongDb = _db;
    if (!strongDb && _expect_db) {
      FSTCFail(@"Transaction runner accessed without underlying db when it expected one");
    }
    if (strongDb) {
      [strongDb startTransaction:label];
    }
    block();
    if (strongDb) {
      [strongDb commitTransaction];
    }
  }

  template <typename F>
  auto operator()(absl::string_view label, F block) const ->
      typename std::enable_if<!std::is_void<decltype(block())>::value, decltype(block())>::type {
    using ReturnT = decltype(block());
    __strong id<FSTTransactional> strongDb = _db;
    if (!strongDb && _expect_db) {
      FSTCFail(@"Transaction runner accessed without underlying db when it expected one");
    }
    if (strongDb) {
      [strongDb startTransaction:label];
    }
    ReturnT result = block();
    if (strongDb) {
      [strongDb commitTransaction];
    }
    return result;
  }
#pragma clang diagnostic pop
  void SetBackingPersistence(id<FSTTransactional> db) {
    _db = db;
    _expect_db = true;
  }

 private:
  __weak id<FSTTransactional> _db;
  bool _expect_db = false;
};

NS_ASSUME_NONNULL_END
