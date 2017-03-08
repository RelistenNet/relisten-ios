//
//  UIImage+PKDownloadButton.h
//  Download
//
//  Created by Pavel on 31/05/15.
//  Copyright (c) 2015 Katunin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (PKDownloadButton)

+ (UIImage *)stopImageOfSize:(CGFloat)size color:(UIColor *)color;
+ (UIImage *)buttonBackgroundWithColor:(UIColor *)color;
+ (UIImage *)highlitedButtonBackgroundWithColor:(UIColor *)color;

@end
