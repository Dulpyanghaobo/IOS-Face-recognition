//
//  AVCaptureViewController.h
//  实时视频Demo
//
//  Created by HanJunqiang on 2017/2/16.
//  Copyright © 2017年 HaRi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JQAVCaptureViewController : UIViewController
@property (nonatomic,strong) void (^SelectedCallBack)(UIImage *img);

@end

