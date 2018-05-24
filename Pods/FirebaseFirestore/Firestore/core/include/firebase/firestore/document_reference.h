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

// TODO(rsgowman): This file isn't intended to be used just yet. It's just an
// outline of what the API might eventually look like. Most of this was
// shamelessly stolen and modified from RTDB's header file, melded with the
// (java) firestore api.

#ifndef FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_DOCUMENT_REFERENCE_H_
#define FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_DOCUMENT_REFERENCE_H_

#include <string>
#include <unordered_map>

#if defined(FIREBASE_USE_STD_FUNCTION)
#include <functional>
#endif

// TODO(rsgowman): Note that RTDB uses:
//   #if defined(FIREBASE_USE_MOVE_OPERATORS) || defined(DOXYGEN
// to protect move operators from older compilers. But all our supported
// compilers support this, so we've skipped the #if guard. This TODO comment is
// here so we don't forget to mention this during the API review, and should be
// removed once this note has migrated to the API review doc.

// TODO(rsgowman): replace these forward decls with appropriate includes (once
// they exist)
namespace firebase {
class App;
template <typename T>
class Future;
}  // namespace firebase

namespace firebase {
namespace firestore {

// TODO(rsgowman): replace these forward decls with appropriate includes (once
// they exist)
class FieldValue;
class DocumentSnapshot;
class Firestore;
class Error;
template <typename T>
class EventListener;
class ListenerRegistration;
class CollectionReference;
class DocumentListenOptions;
// TODO(rsgowman): not quite a forward decl, but required to make the default
// parameter to Set() "compile".
class SetOptions {
 public:
  SetOptions();
};

// TODO(rsgowman): move this into the FieldValue header
#ifdef STLPORT
using MapFieldValue = std::tr1::unordered_map<std::string, FieldValue>;
#else
using MapFieldValue = std::unordered_map<std::string, FieldValue>;
#endif

/**
 * A DocumentReference refers to a document location in a Firestore database and
 * can be used to write, read, or listen to the location. There may or may not
 * exist a document at the referenced location. A DocumentReference can also be
 * used to create a CollectionReference to a subcollection.
 *
 * Create a DocumentReference via Firebase::Document(const string& path).
 *
 * Subclassing Note: Firestore classes are not meant to be subclassed except for
 * use in test mocks. Subclassing is not supported in production code and new
 * SDK releases may break code that does so.
 */
class DocumentReference {
 public:
  /**
   * @brief Default constructor. This creates an invalid DocumentReference.
   * Attempting to perform any operations on this reference will fail (and cause
   * a crash) unless a valid DocumentReference has been assigned to it.
   */
  DocumentReference();

  /**
   * @brief Copy constructor. It's totally okay (and efficient) to copy
   * DocumentReference instances, as they simply point to the same location in
   * the database.
   *
   * @param[in] reference DocumentReference to copy from.
   */
  DocumentReference(const DocumentReference& reference);

  /**
   * @brief Move constructor. Moving is an efficient operation for
   * DocumentReference instances.
   *
   * @param[in] reference DocumentReference to move data from.
   */
  DocumentReference(DocumentReference&& reference);

  virtual ~DocumentReference();

  /**
   * @brief Copy assignment operator. It's totally okay (and efficient) to copy
   * DocumentReference instances, as they simply point to the same location in
   * the database.
   *
   * @param[in] reference DocumentReference to copy from.
   *
   * @returns Reference to the destination DocumentReference.
   */
  DocumentReference& operator=(const DocumentReference& reference);

  /**
   * @brief Move assignment operator. Moving is an efficient operation for
   * DocumentReference instances.
   *
   * @param[in] reference DocumentReference to move data from.
   *
   * @returns Reference to the destination DocumentReference.
   */
  DocumentReference& operator=(DocumentReference&& reference);

  /**
   * @brief Returns the Firestore instance associated with this document
   * reference.
   *
   * The pointer will remain valid indefinitely.
   *
   * @returns Firebase Firestore instance that this DocumentReference refers to.
   */
  virtual const Firestore* firestore() const;

  /**
   * @brief Returns the Firestore instance associated with this document
   * reference.
   *
   * The pointer will remain valid indefinitely.
   *
   * @returns Firebase Firestore instance that this DocumentReference refers to.
   */
  virtual Firestore* firestore();

  /**
   * @brief Returns the string id of this document location.
   *
   * The pointer is only valid while the DocumentReference remains in memory.
   *
   * @returns String id of this document location, which will remain valid in
   * memory until the DocumentReference itself goes away.
   */
  virtual const char* id() const;

  /**
   * @brief Returns the string id of this document location.
   *
   * @returns String id of this document location.
   */
  virtual std::string id_string() const;

  /**
   * @brief Returns the path of this document (relative to the root of the
   * database) as a slash-separated string.
   *
   * The pointer is only valid while the DocumentReference remains in memory.
   *
   * @returns String path of this document location, which will remain valid in
   * memory until the DocumentReference itself goes away.
   */
  virtual const char* path() const;

  /**
   * @brief Returns the path of this document (relative to the root of the
   * database) as a slash-separated string.
   *
   * @returns String path of this document location.
   */
  virtual std::string path_string() const;

  /**
   * @brief Returns a CollectionReference to the collection that contains this
   * document.
   */
  virtual CollectionReference get_parent() const;

  /**
   * @brief Returns a CollectionReference instance that refers to the
   * subcollection at the specified path relative to this document.
   *
   * @param[in] collection_path A slash-separated relative path to a
   * subcollection. The pointer only needs to be valid during this call.
   *
   * @return The CollectionReference instance.
   */
  virtual CollectionReference Collection(const char* collection_path) const;

  /**
   * @brief Returns a CollectionReference instance that refers to the
   * subcollection at the specified path relative to this document.
   *
   * @param[in] collection_path A slash-separated relative path to a
   * subcollection.
   *
   * @return The CollectionReference instance.
   */
  virtual CollectionReference Collection(
      const std::string& collection_path) const;

  /**
   * @brief Reads the document referenced by this DocumentReference.
   *
   * @return A Future that will be resolved with the contents of the Document at
   * this DocumentReference.
   */
  virtual Future<DocumentSnapshot> Get() const;

  /**
   * @brief Writes to the document referred to by this DocumentReference.
   *
   * If the document does not yet exist, it will be created. If you pass
   * SetOptions, the provided data can be merged into an existing document.
   *
   * @param[in] data A map of the fields and values for the document.
   * @param[in] options An object to configure the set behavior.
   *
   * @return A Future that will be resolved when the write finishes.
   */
  virtual Future<void> Set(const MapFieldValue& data,
                           const SetOptions& options = SetOptions());

  /**
   * @brief Updates fields in the document referred to by this
   * DocumentReference.
   *
   * If no document exists yet, the update will fail.
   *
   * @param[in] data A map of field / value pairs to update. Fields can contain
   * dots to reference nested fields within the document.
   *
   * @return A Future that will be resolved when the write finishes.
   */
  virtual Future<void> Update(const MapFieldValue& data);

  /**
   * @brief Removes the document referred to by this DocumentReference.
   *
   * @return A Task that will be resolved when the delete completes.
   */
  virtual Future<void> Delete();

  /**
   * @brief Starts listening to the document referenced by this
   * DocumentReference.
   *
   * @param[in] listener The event listener that will be called with the
   * snapshots, which must remain in memory until you remove the listener from
   * this DocumentReference. (Ownership is not transferred; you are responsible
   * for making sure that listener is valid as long as this DocumentReference is
   * valid and the listener is registered.)
   *
   * @return A registration object that can be used to remove the listener.
   */
  virtual ListenerRegistration AddSnapshotListener(
      EventListener<DocumentSnapshot>* listener);

  /**
   * @brief Starts listening to the document referenced by this
   * DocumentReference.
   *
   * @param[in] options The options to use for this listen.
   * @param[in] listener The event listener that will be called with the
   * snapshots, which must remain in memory until you remove the listener from
   * this DocumentReference. (Ownership is not transferred; you are responsible
   * for making sure that listener is valid as long as this DocumentReference is
   * valid and the listener is registered.)
   *
   * @return A registration object that can be used to remove the listener.
   */
  virtual ListenerRegistration AddSnapshotListener(
      const DocumentListenOptions& options,
      EventListener<DocumentSnapshot>* listener);

#if defined(FIREBASE_USE_STD_FUNCTION) || defined(DOXYGEN)
  /**
   * @brief Starts listening to the document referenced by this
   * DocumentReference.
   *
   * @param[in] callback function or lambda to call. When this function is
   * called, exactly one of the parameters will be non-null.
   *
   * @return A registration object that can be used to remove the listener.
   *
   * @note This method is not available when using STLPort on Android, as
   * std::function is not supported on STLPort.
   */
  virtual ListenerRegistration AddSnapshotListener(
      std::function<void(const DocumentSnapshot*, const Error*)> callback);

  /**
   * @brief Starts listening to the document referenced by this
   * DocumentReference.
   *
   * @param[in] options The options to use for this listen.
   * @param[in] callback function or lambda to call. When this function is
   * called, exactly one of the parameters will be non-null.
   *
   * @return A registration object that can be used to remove the listener.
   *
   * @note This method is not available when using STLPort on Android, as
   * std::function is not supported on STLPort.
   */
  virtual ListenerRegistration AddSnapshotListener(
      const DocumentListenOptions& options,
      std::function<void(const DocumentSnapshot*, const Error*)> callback);
#endif  // defined(FIREBASE_USE_STD_FUNCTION) || defined(DOXYGEN)
};

// TODO(rsgowman): probably define and inline here.
bool operator==(const DocumentReference& lhs, const DocumentReference& rhs);

inline bool operator!=(const DocumentReference& lhs,
                       const DocumentReference& rhs) {
  return !(lhs == rhs);
}

// TODO(rsgowman): probably define and inline here.
bool operator<(const DocumentReference& lhs, const DocumentReference& rhs);

inline bool operator>(const DocumentReference& lhs,
                      const DocumentReference& rhs) {
  return rhs < lhs;
}

inline bool operator<=(const DocumentReference& lhs,
                       const DocumentReference& rhs) {
  return !(lhs > rhs);
}

inline bool operator>=(const DocumentReference& lhs,
                       const DocumentReference& rhs) {
  return !(lhs < rhs);
}

}  // namespace firestore
}  // namespace firebase

namespace std {
// TODO(rsgowman): NB that specialization of std::hash deviates from the Google
// C++ style guide. But we think this is probably ok in this case since:
// a) It's the standard way of doing this outside of Google (as the style guide
// itself points out), and
// b) This has a straightforward hash function anyway (just hash the path) so I
// don't think the concerns in the style guide are going to bite us.
//
// Raise this concern during the API review.
template <>
struct hash<firebase::firestore::DocumentReference> {
  std::size_t operator()(
      const firebase::firestore::DocumentReference& doc_ref) const;
};
}  // namespace std

#endif  // FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_DOCUMENT_REFERENCE_H_
