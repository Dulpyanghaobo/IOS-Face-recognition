//
//  Utils.h
//  TestFramework
//
//  Created by yhb on 2020/11/20.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject
+ (CVPixelBufferRef)bytesToPixelBuffer:(size_t)width
                                height:(size_t)height
                                format:(FourCharCode)format
                           baseAddress:(void *)baseAddress
                           bytesPerRow:(size_t)bytesPerRow;
+ (CVPixelBufferRef)planarBytesToPixelBuffer:(size_t)width
                                      height:(size_t)height
                                      format:(FourCharCode)format
                                 baseAddress:(void *)baseAddress
                                    dataSize:(size_t)dataSize
                                  planeCount:(size_t)planeCount
                                   planeData:(NSArray *)planeData;

@end

NS_ASSUME_NONNULL_END
