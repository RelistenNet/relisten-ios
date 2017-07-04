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

#import "ObjectiveBASS.h"
#import "bass.h"
#import "bassmix.h"
#import "bass_fx.h"

FOUNDATION_EXPORT double BASSGaplessAudioPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char BASSGaplessAudioPlayerVersionString[];

