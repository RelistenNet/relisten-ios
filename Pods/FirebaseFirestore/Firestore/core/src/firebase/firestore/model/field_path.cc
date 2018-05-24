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

#include "Firestore/core/src/firebase/firestore/model/field_path.h"

#include <algorithm>
#include <utility>

#include "Firestore/core/src/firebase/firestore/util/firebase_assert.h"
#include "absl/strings/str_join.h"
#include "absl/strings/str_replace.h"
#include "absl/strings/str_split.h"

namespace firebase {
namespace firestore {
namespace model {

namespace {

/**
 * True if the string could be used as a segment in a field path without
 * escaping. Valid identifies follow the regex [a-zA-Z_][a-zA-Z0-9_]*
 */
bool IsValidIdentifier(const std::string& segment) {
  if (segment.empty()) {
    return false;
  }

  // Note: strictly speaking, only digits are guaranteed by the Standard to
  // be a contiguous range, while alphabetic characters may have gaps. Ignoring
  // this peculiarity, because it doesn't affect the platforms that Firestore
  // supports.
  const unsigned char first = segment.front();
  if (first != '_' && (first < 'a' || first > 'z') &&
      (first < 'A' || first > 'Z')) {
    return false;
  }
  for (size_t i = 1; i != segment.size(); ++i) {
    const unsigned char c = segment[i];
    if (c != '_' && (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') &&
        (c < '0' || c > '9')) {
      return false;
    }
  }

  return true;
}

}  // namespace

FieldPath FieldPath::FromServerFormat(const absl::string_view path) {
  // TODO(b/37244157): Once we move to v1beta1, we should make this more
  // strict. Right now, it allows non-identifier path components, even if they
  // aren't escaped. Technically, this will mangle paths with backticks in
  // them used in v1alpha1, but that's fine.

  SegmentsT segments;
  std::string segment;
  segment.reserve(path.size());

  // string_view doesn't have a c_str() method, because it might not be
  // null-terminated. Assertions expect C strings, so construct std::string on
  // the fly, so that c_str() might be called on it.
  const auto to_string = [](const absl::string_view view) {
    return std::string{view.data(), view.data() + view.size()};
  };
  const auto finish_segment = [&segments, &segment, &path, &to_string] {
    FIREBASE_ASSERT_MESSAGE(
        !segment.empty(),
        "Invalid field path (%s). Paths must not be empty, begin with "
        "'.', end with '.', or contain '..'",
        to_string(path).c_str());
    // Move operation will clear segment, but capacity will remain the same
    // (not, strictly speaking, required by the standard, but true in practice).
    segments.push_back(std::move(segment));
  };

  // Inside backticks, dots are treated literally.
  bool inside_backticks = false;
  size_t i = 0;
  while (i < path.size()) {
    const char c = path[i];
    // std::string (and string_view) may contain embedded nulls. For full
    // compatibility with Objective C behavior, finish upon encountering the
    // first terminating null.
    if (c == '\0') {
      break;
    }

    switch (c) {
      case '.':
        if (!inside_backticks) {
          finish_segment();
        } else {
          segment += c;
        }
        break;

      case '`':
        inside_backticks = !inside_backticks;
        break;

      case '\\':
        // TODO(b/37244157): Make this a user-facing exception once we
        // finalize field escaping.
        FIREBASE_ASSERT_MESSAGE(i + 1 != path.size(),
                                "Trailing escape characters not allowed in %s",
                                to_string(path).c_str());
        ++i;
        segment += path[i];
        break;

      default:
        segment += c;
        break;
    }
    ++i;
  }
  finish_segment();

  FIREBASE_ASSERT_MESSAGE(!inside_backticks, "Unterminated ` in path %s",
                          to_string(path).c_str());

  return FieldPath{std::move(segments)};
}

const FieldPath& FieldPath::EmptyPath() {
  static const FieldPath empty_path;
  return empty_path;
}

const FieldPath& FieldPath::KeyFieldPath() {
  static const FieldPath key_field_path{FieldPath::kDocumentKeyPath};
  return key_field_path;
}

bool FieldPath::IsKeyFieldPath() const {
  return size() == 1 && first_segment() == FieldPath::kDocumentKeyPath;
}

std::string FieldPath::CanonicalString() const {
  const auto escaped_segment = [](const std::string& segment) {
    auto escaped = absl::StrReplaceAll(segment, {{"\\", "\\\\"}, {"`", "\\`"}});
    const bool needs_escaping = !IsValidIdentifier(escaped);
    if (needs_escaping) {
      escaped.insert(escaped.begin(), '`');
      escaped.push_back('`');
    }
    return escaped;
  };
  return absl::StrJoin(
      begin(), end(), ".",
      [escaped_segment](std::string* out, const std::string& segment) {
        out->append(escaped_segment(segment));
      });
}

}  // namespace model
}  // namespace firestore
}  // namespace firebase
