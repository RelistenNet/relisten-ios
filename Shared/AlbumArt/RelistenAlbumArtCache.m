//
//  RelistenAlbumArtCache.m
//  PhishOD
//
//  Created by Alec Gorge on 10/7/15.
//  Copyright © 2015 Alec Gorge. All rights reserved.
//

#import "RelistenAlbumArtCache.h"

#import <ChameleonFramework/Chameleon.h>
#import <EDColor/EDColor.h>

#import "RelistenAlbumArts.h"

@implementation RelistenAlbumArtCache

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedFoo;
    dispatch_once(&once, ^ {
        sharedFoo = RelistenAlbumArtCache.new;
    });
    return sharedFoo;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self setupImageCache];
    }
    return self;
}

- (UIColor *)colorForYear:(NSInteger)year artist:(NSString *)artist {
    static NSArray *sYearColors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sYearColors = @[
                        [UIColor flatBlackColor],
                        [UIColor flatBlueColor],
                        [UIColor flatBrownColor],
                        [UIColor flatCoffeeColor],
                        [UIColor flatForestGreenColor],
                        [UIColor flatGrayColor],
                        [UIColor flatGreenColor],
                        [UIColor flatLimeColor],
                        [UIColor flatMagentaColor],
                        [UIColor flatMaroonColor],
                        [UIColor flatMintColor],
                        [UIColor flatNavyBlueColor],
                        [UIColor flatOrangeColor],
                        [UIColor flatPinkColor],
                        [UIColor flatPlumColor],
                        [UIColor flatPowderBlueColor],
                        [UIColor flatPurpleColor],
                        [UIColor flatRedColor],
                        [UIColor flatSandColor],
                        [UIColor flatSkyBlueColor],
                        [UIColor flatTealColor],
                        [UIColor flatWatermelonColor],
                        [UIColor flatWhiteColor],
                        [UIColor flatYellowColor],
                        [UIColor flatBlackColorDark],
                        [UIColor flatBlueColorDark],
                        [UIColor flatBrownColorDark],
                        [UIColor flatCoffeeColorDark],
                        [UIColor flatForestGreenColorDark],
                        [UIColor flatGrayColorDark],
                        [UIColor flatGreenColorDark],
                        [UIColor flatLimeColorDark],
                        [UIColor flatMagentaColorDark],
                        [UIColor flatMaroonColorDark],
                        [UIColor flatMintColorDark],
                        [UIColor flatNavyBlueColorDark],
                        [UIColor flatOrangeColorDark],
                        [UIColor flatPinkColorDark],
                        [UIColor flatPlumColorDark],
                        [UIColor flatPowderBlueColorDark],
                        [UIColor flatPurpleColorDark],
                        [UIColor flatRedColorDark],
                        [UIColor flatSandColorDark],
                        [UIColor flatSkyBlueColorDark],
                        [UIColor flatTealColorDark],
                        [UIColor flatWatermelonColorDark],
                        [UIColor flatWhiteColorDark],
                        [UIColor flatYellowColorDark]
                    ];

    });
    return [sYearColors objectAtIndex:((year ^ artist.hash) % sYearColors.count)];
}

- (void)setupImageCache {
    FICImageFormat *small = [[FICImageFormat alloc] init];
    small.name = PHODImageFormatSmall;
    small.family = PHODImageFamily;
    small.style = FICImageFormatStyle32BitBGR;
    small.imageSize = CGSizeMake(112 * 2, 112 * 2);
    small.maximumCount = 250;
    small.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    small.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *medium = [[FICImageFormat alloc] init];
    medium.name = PHODImageFormatMedium;
    medium.family = PHODImageFamily;
    medium.style = FICImageFormatStyle32BitBGR;
    medium.imageSize = CGSizeMake(512, 512);
    medium.maximumCount = 250;
    medium.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    medium.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *full = [[FICImageFormat alloc] init];
    full.name = PHODImageFormatFull;
    full.family = PHODImageFamily;
    full.style = FICImageFormatStyle32BitBGR;
    full.imageSize = CGSizeMake(768, 768);
    full.maximumCount = 3;
    full.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    full.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[small, medium, full];
    
    /*
    [self.sharedCache reset];
    NSString *p = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:[p stringByAppendingPathComponent:@"ImageTables"]
                                               error:&err];
     */
    
    self.sharedCache.delegate = self;
    self.sharedCache.formats = imageFormats;
}

- (FICImageCache *)sharedCache {
    return FICImageCache.sharedImageCache;
}

- (void)imageCache:(FICImageCache *)imageCache
wantsSourceImageForEntity:(id<FICEntity>)entity
    withFormatName:(NSString *)formatName
   completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Fetch the desired source image by making a network request
        NSURL *requestURL = [entity fic_sourceImageURLWithFormatName:formatName];
        
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:requestURL
                                                    resolvingAgainstBaseURL:NO];
        
        NSString *artist = [self valueForKey:@"artist"
                                fromQueryItems:urlComponents.queryItems];
        NSString *date = [self valueForKey:@"date"
                            fromQueryItems:urlComponents.queryItems];
        NSString *venue = [self valueForKey:@"venue"
                             fromQueryItems:urlComponents.queryItems];
        NSString *location = [self valueForKey:@"location"
                                fromQueryItems:urlComponents.queryItems];
        
        NSInteger year = [[date substringToIndex:4] integerValue];
        UIColor *baseColor = [[self colorForYear:year artist:artist] darken:0.05];
        
        NSInteger month = [[date substringWithRange:NSMakeRange(5, 2)] integerValue];
        
        baseColor = [baseColor offsetWithHue:0.0f
                                  saturation:((month - 1) *  2) / 100.0f
                                   lightness:((month - 1) * -2) / 100.0f
                                       alpha:1.0f];
        
        NSInteger day = [[date substringWithRange:NSMakeRange(8, 2)] integerValue];
        
        UIGraphicsBeginImageContext(CGSizeMake(768, 768));
        
        BOOL allSame = NO;
        
        if(!allSame && day % 4 == 1) {
            [RelistenAlbumArts drawShatterExplosionWithBaseColor:baseColor
                                                         date:date
                                                        venue:venue
                                                  andLocation:location];
        }
        else if(!allSame && day % 4 == 2) {
            [RelistenAlbumArts drawRandomFlowersWithBaseColor:baseColor
                                                         date:date
                                                        venue:venue
                                                  andLocation:location];
        }
        else if(!allSame && day % 4 == 3) {
            [RelistenAlbumArts drawSplashWithBaseColor:baseColor
                                                         date:date
                                                        venue:venue
                                                  andLocation:location];
        }
        else if(allSame || day % 4 == 0) {
            [RelistenAlbumArts drawCityGlittersWithBaseColor:baseColor
                                                         date:date
                                                        venue:venue
                                                  andLocation:location];
        }

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();

        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
    });
}

- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

@end
