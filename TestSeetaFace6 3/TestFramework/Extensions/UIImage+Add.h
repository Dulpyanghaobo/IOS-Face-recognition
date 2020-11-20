//
//  UIImage+Add.h
//  TestFramework
//
//  Created by yhb on 2020/11/18.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Add)
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size ;
- (UIImage *)imageByRoundCornerRadius:(CGFloat)radius ;
@end

NS_ASSUME_NONNULL_END
