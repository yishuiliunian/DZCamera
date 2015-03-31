//
//  UIImage+PSTools.h
//  QQPicShow
//
//  Created by Stone Dong on 13-10-21.
//  Copyright (c) 2013年 Tencent SNS Terminal Develope Center. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface UIImage (PSTools)
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;
@end
