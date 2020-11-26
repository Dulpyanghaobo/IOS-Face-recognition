//
//  IDInfoViewControllers.h
//  TestFramework
//
//  Created by yhb on 2020/11/24.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class IDInfo;

@interface IDInfoViewControllers : UIViewController
// 身份证信息
@property (nonatomic,strong) IDInfo *IDInfo;

// 身份证图像
@property (nonatomic,strong) UIImage *IDImage;
@end

NS_ASSUME_NONNULL_END
