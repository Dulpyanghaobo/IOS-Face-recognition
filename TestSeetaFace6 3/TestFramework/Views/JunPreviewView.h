//
//  JunPreviewView.h
//  TestFramework
//
//  Created by yhb on 2020/11/17.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GLKit;
@import AVFoundation;
@import CoreMedia;

NS_ASSUME_NONNULL_BEGIN
@protocol HandleMetadataOutputDelegate <NSObject>

-(void)handleOutput:(NSArray<AVMetadataObject *>*)faceObject preview:(AVCaptureVideoPreviewLayer *)preview;

@end
@interface JunPreviewView : UIView<HandleMetadataOutputDelegate>

@end

NS_ASSUME_NONNULL_END
