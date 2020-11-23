//
//  SeetaImageModel.h
//  TestFramework
//
//  Created by yhb on 2020/11/20.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeetaImageModel : NSObject

/** 脸部位置*/
@property (nonatomic, strong) NSString *facePoint;
/** 是否为真脸*/
@property (nonatomic, assign) BOOL isREALFace;
/** 清晰度*/
@property (nonatomic, assign) float clarity;
/** 真实度*/
@property (nonatomic, assign) float reality;
/** 大致年龄*/
@property (nonatomic, assign) int age;
/** 性别*/
@property (nonatomic, strong) NSString *gender;
/** 图片质量*/
@property (nonatomic,strong) NSString *quatiy;


@end

NS_ASSUME_NONNULL_END
