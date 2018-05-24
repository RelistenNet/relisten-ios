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

#import "Firestore/Source/API/FIRTransaction+Internal.h"

#import "Firestore/Source/API/FIRDocumentReference+Internal.h"
#import "Firestore/Source/API/FIRDocumentSnapshot+Internal.h"
#import "Firestore/Source/API/FIRFirestore+Internal.h"
#import "Firestore/Source/API/FSTUserDataConverter.h"
#import "Firestore/Source/Core/FSTTransaction.h"
#import "Firestore/Source/Model/FSTDocument.h"
#import "Firestore/Source/Util/FSTAssert.h"
#import "Firestore/Source/Util/FSTUsageValidation.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FIRTransaction

@interface FIRTransaction ()

- (instancetype)initWithTransaction:(FSTTransaction *)transaction
                          firestore:(FIRFirestore *)firestore NS_DESIGNATED_INITIALIZER;

@property(nonatomic, strong, readonly) FSTTransaction *internalTransaction;
@property(nonatomic, strong, readonly) FIRFirestore *firestore;
@end

@implementation FIRTransaction (Internal)

+ (instancetype)transactionWithFSTTransaction:(FSTTransaction *)transaction
                                    firestore:(FIRFirestore *)firestore {
  return [[FIRTransaction alloc] initWithTransaction:transaction firestore:firestore];
}

@end

@implementation FIRTransaction

- (instancetype)initWithTransaction:(FSTTransaction *)transaction
                          firestore:(FIRFirestore *)firestore {
  self = [super init];
  if (self) {
    _internalTransaction = transaction;
    _firestore = firestore;
  }
  return self;
}

- (FIRTransaction *)setData:(NSDictionary<NSString *, id> *)data
                forDocument:(FIRDocumentReference *)document {
  return [self setData:data forDocument:document merge:NO];
}

- (FIRTransaction *)setData:(NSDictionary<NSString *, id> *)data
                forDocument:(FIRDocumentReference *)document
                      merge:(BOOL)merge {
  [self validateReference:document];
  FSTParsedSetData *parsed = merge ? [self.firestore.dataConverter parsedMergeData:data]
                                   : [self.firestore.dataConverter parsedSetData:data];
  [self.internalTransaction setData:parsed forDocument:document.key];
  return self;
}

- (FIRTransaction *)updateData:(NSDictionary<id, id> *)fields
                   forDocument:(FIRDocumentReference *)document {
  [self validateReference:document];
  FSTParsedUpdateData *parsed = [self.firestore.dataConverter parsedUpdateData:fields];
  [self.internalTransaction updateData:parsed forDocument:document.key];
  return self;
}

- (FIRTransaction *)deleteDocument:(FIRDocumentReference *)document {
  [self validateReference:document];
  [self.internalTransaction deleteDocument:document.key];
  return self;
}

- (void)getDocument:(FIRDocumentReference *)document
         completion:(void (^)(FIRDocumentSnapshot *_Nullable document,
                              NSError *_Nullable error))completion {
  [self validateReference:document];
  [self.internalTransaction
      lookupDocumentsForKeys:{document.key}
                  completion:^(NSArray<FSTMaybeDocument *> *_Nullable documents,
                               NSError *_Nullable error) {
                    if (error) {
                      completion(nil, error);
                      return;
                    }
                    FSTAssert(documents.count == 1,
                              @"Mismatch in docs returned from document lookup.");
                    FSTMaybeDocument *internalDoc = documents.firstObject;
                    if ([internalDoc isKindOfClass:[FSTDeletedDocument class]]) {
                      completion(nil, nil);
                      return;
                    }
                    FIRDocumentSnapshot *doc =
                        [FIRDocumentSnapshot snapshotWithFirestore:self.firestore
                                                       documentKey:internalDoc.key
                                                          document:(FSTDocument *)internalDoc
                                                         fromCache:NO];
                    completion(doc, nil);
                  }];
}

- (FIRDocumentSnapshot *_Nullable)getDocument:(FIRDocumentReference *)document
                                        error:(NSError *__autoreleasing *)error {
  [self validateReference:document];
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block FIRDocumentSnapshot *result;
  // We have to explicitly assign the innerError into a local to cause it to retain correctly.
  __block NSError *outerError = nil;
  [self getDocument:document
         completion:^(FIRDocumentSnapshot *_Nullable snapshot, NSError *_Nullable innerError) {
           result = snapshot;
           outerError = innerError;
           dispatch_semaphore_signal(semaphore);
         }];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  if (error) {
    *error = outerError;
  }
  return result;
}

- (void)validateReference:(FIRDocumentReference *)reference {
  if (reference.firestore != self.firestore) {
    FSTThrowInvalidArgument(@"Provided document reference is from a different Firestore instance.");
  }
}

@end

NS_ASSUME_NONNULL_END
