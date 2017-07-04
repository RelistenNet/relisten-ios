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

#import "AGAudioItem.h"
#import "AGAudioItemCollection.h"
#import "AGAudioPlayer.h"
#import "AGAudioPlayerUpNextQueue.h"
#import "AGCachable.h"
#import "AGDurationHelper.h"

FOUNDATION_EXPORT double AGAudioPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char AGAudioPlayerVersionString[];

