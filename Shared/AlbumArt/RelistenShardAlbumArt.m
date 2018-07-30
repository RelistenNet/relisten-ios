//
//  RelistenShardAlbumArt.m
//  PhishOD
//
//  Created by Alec Gorge on 9/25/15.
//  Copyright © 2015 Alec Gorge. All rights reserved.
//

#import "RelistenShardAlbumArt.h"

#import <ChameleonFramework/Chameleon.h>
#import <EDColor/EDColor.h>

#import "RelistenShardStyle.h"
#import "RelistenAlbumArts.h"

@implementation RelistenShardAlbumArt

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIGraphicsBeginImageContext(CGSizeMake(768, 768));
        
        NSArray *colors = @[
                            [UIColor colorWithRed: 0.260 green: 0.000 blue: 0.002 alpha: 1],
                            [UIColor colorWithRed: 0.421 green: 0.042 blue: 0.068 alpha: 1],
                            [UIColor colorWithRed: 0.595 green: 0.152 blue: 0.171 alpha: 1],
                            [UIColor colorWithRed: 0.784 green: 0.327 blue: 0.342 alpha: 1],
                            [UIColor colorWithRed: 0.992 green: 0.593 blue: 0.604 alpha: 1],
                            [UIColor colorWithRed: 1.000 green: 1.000 blue: 1.000 alpha: 1]
                            ];
        
        colors = [[NSArray arrayOfColorsWithColorScheme:ColorSchemeAnalogous
                                             usingColor:[UIColor flatRedColorDark]
                                         withFlatScheme:NO] arrayByAddingObject:UIColor.whiteColor];
        
        UIColor *baseColor = [[UIColor flatYellowColorDark] darkenByPercentage:0.3];
        colors = @[
                   baseColor,
                   [baseColor lightenByPercentage:.1],
                   [baseColor lightenByPercentage:.2],
                   [baseColor lightenByPercentage:.4],
                   [baseColor lightenByPercentage:.8],
                   UIColor.whiteColor
                   ];
        
//        colors = [NSArray arrayOfColorsWithColorScheme:ColorSchemeTriadic
//                                            usingColor:[UIColor flatRedColorDark]
//                                        withFlatScheme:NO];
//        
//        colors = @[
//                   colors[0],
//                   colors[1],
//                   colors[4],
//                   colors[3],
//                   colors[2],
//                   UIColor.whiteColor
//                   ];
        
        CGFloat randomFlowerTransform[5][3] = {
            {-11.3280589,-9.818462023,-8.794142144},
            {-12.86407494,-6.368568016,-0.52404444},
            {0,0,0},
            {16.40182009,0.099009545,-3.887684593},
            {22.23518689,-8.385507143,-6.493886917}
        };
        baseColor = [UIColor colorWithRed:152.0f/255.0f
                                    green:39.0f/255.0f
                                     blue:44.0f/255.0f
                                    alpha:1.0];
        
        baseColor = [[UIColor flatRedColorDark] darkenByPercentage:.1];
        
        NSMutableArray *arr = NSMutableArray.array;
        for(int i = 0; i < 5; i++) {
            [arr addObject:[baseColor offsetWithLightness:randomFlowerTransform[i][0]
                                                        a:randomFlowerTransform[i][1]
                                                        b:randomFlowerTransform[i][2]
                                                    alpha:0.0f]];
        }
        
        colors = arr;
        
        [RelistenAlbumArts drawShatterExplosionWithBaseColor:baseColor
                                                  date:@"1998-05-05 :)"
                                                 venue:@"Alpha Delta Phi Fraternity, Trinity College"
                                           andLocation:@"Prague, Czech Republic"];
        
        self.backgroundColor = UIColor.whiteColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    [StyleKitName drawCanvas1];
//}

@end
