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

#import "Firestore/Source/Model/FSTDocument.h"

#include <utility>

#import "Firestore/Source/Core/FSTSnapshotVersion.h"
#import "Firestore/Source/Model/FSTFieldValue.h"
#import "Firestore/Source/Util/FSTAssert.h"

#include "Firestore/core/src/firebase/firestore/model/document_key.h"
#include "Firestore/core/src/firebase/firestore/model/field_path.h"
#include "Firestore/core/src/firebase/firestore/util/string_apple.h"

namespace util = firebase::firestore::util;
using firebase::firestore::model::DocumentKey;
using firebase::firestore::model::FieldPath;

NS_ASSUME_NONNULL_BEGIN

@interface FSTMaybeDocument ()

- (instancetype)initWithKey:(DocumentKey)key
                    version:(FSTSnapshotVersion *)version NS_DESIGNATED_INITIALIZER;

@end

@implementation FSTMaybeDocument {
  DocumentKey _key;
}

- (instancetype)initWithKey:(DocumentKey)key version:(FSTSnapshotVersion *)version {
  FSTAssert(!!version, @"Version must not be nil.");
  self = [super init];
  if (self) {
    _key = std::move(key);
    _version = version;
  }
  return self;
}

- (id)copyWithZone:(NSZone *_Nullable)zone {
  // All document types are immutable
  return self;
}

- (const DocumentKey &)key {
  return _key;
}

@end

@implementation FSTDocument

+ (instancetype)documentWithData:(FSTObjectValue *)data
                             key:(DocumentKey)key
                         version:(FSTSnapshotVersion *)version
               hasLocalMutations:(BOOL)mutations {
  return [[FSTDocument alloc] initWithData:data
                                       key:std::move(key)
                                   version:version
                         hasLocalMutations:mutations];
}

- (instancetype)initWithData:(FSTObjectValue *)data
                         key:(DocumentKey)key
                     version:(FSTSnapshotVersion *)version
           hasLocalMutations:(BOOL)mutations {
  self = [super initWithKey:std::move(key) version:version];
  if (self) {
    _data = data;
    _localMutations = mutations;
  }
  return self;
}

- (BOOL)isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[FSTDocument class]]) {
    return NO;
  }

  FSTDocument *otherDoc = other;
  return [self.key isEqual:otherDoc.key] && [self.version isEqual:otherDoc.version] &&
         [self.data isEqual:otherDoc.data] && self.hasLocalMutations == otherDoc.hasLocalMutations;
}

- (NSUInteger)hash {
  NSUInteger result = [self.key hash];
  result = result * 31 + [self.version hash];
  result = result * 31 + [self.data hash];
  result = result * 31 + (self.hasLocalMutations ? 1 : 0);
  return result;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<FSTDocument: key:%s version:%@ localMutations:%@ data:%@>",
                                    self.key.ToString().c_str(), self.version,
                                    self.localMutations ? @"YES" : @"NO", self.data];
}

- (nullable FSTFieldValue *)fieldForPath:(const FieldPath &)path {
  return [_data valueForPath:path];
}

@end

@implementation FSTDeletedDocument

+ (instancetype)documentWithKey:(DocumentKey)key version:(FSTSnapshotVersion *)version {
  return [[FSTDeletedDocument alloc] initWithKey:std::move(key) version:version];
}

- (BOOL)isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[FSTDeletedDocument class]]) {
    return NO;
  }

  FSTDocument *otherDoc = other;
  return [self.key isEqual:otherDoc.key] && [self.version isEqual:otherDoc.version];
}

- (NSUInteger)hash {
  NSUInteger result = [self.key hash];
  result = result * 31 + [self.version hash];
  return result;
}

@end

const NSComparator FSTDocumentComparatorByKey =
    ^NSComparisonResult(FSTMaybeDocument *doc1, FSTMaybeDocument *doc2) {
      return [doc1.key compare:doc2.key];
    };

NS_ASSUME_NONNULL_END
