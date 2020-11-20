//
//  UIImage+OpenCV.m
//  seeta-sdk-ios
//
//  Created by 徐芃 on 2018/7/1.
//  Copyright © 2018年 徐芃. All rights reserved.
//

#import "UIImage+OpenCV.h"

@implementation UIImage (OpenCV)
-(instancetype)initWithMat:(const cv::Mat &) cvMat {
    cv::Mat local_cvMat = cvMat.clone();
    cv::cvtColor(local_cvMat, local_cvMat, cv::COLOR_BGR2RGB);
    NSData *data = [NSData dataWithBytes:local_cvMat.data length:local_cvMat.elemSize() * local_cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (local_cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(local_cvMat.cols,                            //width
                                        local_cvMat.rows,                            //height
                                        8,                                           //bits per component
                                        8 * local_cvMat.elemSize(),                  //bits per pixel
                                        local_cvMat.step[0],                         //bytesPerRow
                                        colorSpace,                                  //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault, // bitmap info
                                        provider,                                    //CGDataProviderRef
                                        NULL,                                        //decode
                                        false,                                       //should interpolate
                                        kCGRenderingIntentDefault                    //intent
                                        );
    
    UIImage *finalImage = [UIImage imageWithCGImage: imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
-(cv::Mat)cvMatFromUIImage:(UIImage *)image {
//    cv::Mat cvimg = [self CVMat:image];
    std::string *filePath = [self getImagePath:image];
    cv::Mat cvImg = cv::imread(filePath->c_str());
    return  cvImg;
}
//获取照片进行本地转换
- (std::string *)getImagePath:(UIImage *)image {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/2.png"];   // 保存文件的名称
    BOOL result = [UIImagePNGRepresentation(image) writeToFile: filePath atomically:YES]; // 保存成功会返回YES
    if (result) {
        NSLog(@"保存成功");
    }else{
        NSLog(@"保存失败");
    }
    std::string *pathss =new std::string([filePath UTF8String]);
    
    return pathss;
}
@end
