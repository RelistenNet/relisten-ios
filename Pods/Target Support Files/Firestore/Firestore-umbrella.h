#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FIRCollectionReference.h"
#import "FIRDocumentChange.h"
#import "FIRDocumentReference.h"
#import "FIRDocumentSnapshot.h"
#import "FIRFieldPath.h"
#import "FIRFieldValue.h"
#import "FIRFirestore.h"
#import "FIRFirestoreErrors.h"
#import "FIRFirestoreSettings.h"
#import "FIRFirestoreSwiftNameSupport.h"
#import "FIRGeoPoint.h"
#import "FIRListenerRegistration.h"
#import "FIRQuery.h"
#import "FIRQuerySnapshot.h"
#import "FIRSetOptions.h"
#import "FIRSnapshotMetadata.h"
#import "FIRTransaction.h"
#import "FIRWriteBatch.h"

FOUNDATION_EXPORT double FirestoreVersionNumber;
FOUNDATION_EXPORT const unsigned char FirestoreVersionString[];

