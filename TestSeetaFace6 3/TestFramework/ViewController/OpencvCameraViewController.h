//
//  OpencvCameraViewController.h
//  TestFramework
//
//  Created by yhb on 2020/11/19.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SeetaImageModel.h"
NS_ASSUME_NONNULL_BEGIN
/** 设置tags状态 */

typedef NS_ENUM(NSInteger, FaceVerifyStatus) {
    FaceVerifyStatusPass,         //!< 真实人脸
    FaceVerifyStatusFake,        //!< 假脸
    FaceVerifyStatusUnVerify,          //!< 无法判断
    FaceVerifyStatusDisfferent,          //!< 不同人脸
    FaceVerifyStatusDetecting,    //!< 正在检测
    
};
typedef NS_ENUM(NSInteger, FaceVerifyAnitSpoofStatus) {
    FaceVerifyAnitSpoofStatusReal,         //!< 真实人脸
    FaceVerifyAnitSpoofStatusFake,        //!< 假脸
    FaceVerifyAnitSpoofStatusUnVerify,          //!< 无法判断
    FaceVerifyAnitSpoofStatusDetecting,    //!< 正在检测
    
};
@interface OpencvCameraViewController : UIViewController

/** 获取身份证的图像信息*/
@property (nonatomic,strong) UIImage *IdCardImg ;

/** 获取身份证上人脸图像信息*/
@property (nonatomic,strong)NSValue *IdCardfacePos ;
/** 人脸识别结果*/
@property (nonatomic, assign) FaceVerifyStatus status;

/** 调整控制器亮度*/
@property (nonatomic, readwrite, assign) CGFloat currentLight;
//是否为真脸
@property (nonatomic, assign) FaceVerifyAnitSpoofStatus spoofStatus;
@property (nonatomic,strong) void (^SelectedCallBack)(BOOL isSuccess);

@end

NS_ASSUME_NONNULL_END
