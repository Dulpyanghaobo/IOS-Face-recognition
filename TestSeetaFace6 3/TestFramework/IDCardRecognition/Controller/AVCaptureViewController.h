//
//  AVCaptureViewController.h
//  实时视频Demo
//
//  Created by HanJunqiang on 2017/2/16.
//  Copyright © 2017年 HaRi. All rights reserved.
//
//  

#import <UIKit/UIKit.h>
#import "IDInfo.h"
@interface AVCaptureViewController : UIViewController
@property (nonatomic,strong) void (^SelectedCallBack)(UIImage *img);
@property (nonatomic,strong) void (^SelectedIdCardInfoCallBack)(IDInfo *info);
@end

