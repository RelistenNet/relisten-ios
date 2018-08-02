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

#import "FastImageCache.h"
#import "FICEntity.h"
#import "FICImageCache+FICErrorLogging.h"
#import "FICImageCache.h"
#import "FICImageFormat.h"
#import "FICImageTable.h"
#import "FICImageTableChunk.h"
#import "FICImageTableEntry.h"
#import "FICImports.h"
#import "FICUtilities.h"

FOUNDATION_EXPORT double FastImageCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char FastImageCacheVersionString[];

