/*
 * Copyright 2018 Google
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

#include "Firestore/core/src/firebase/firestore/auth/user.h"

#include "Firestore/core/src/firebase/firestore/util/firebase_assert.h"

namespace firebase {
namespace firestore {
namespace auth {

User::User() : is_authenticated_(false) {
}

User::User(const absl::string_view uid) : uid_(uid), is_authenticated_(true) {
  FIREBASE_ASSERT(!uid.empty());
}

const User& User::Unauthenticated() {
  static const User kUnauthenticated;
  return kUnauthenticated;
}

}  // namespace auth
}  // namespace firestore
}  // namespace firebase
