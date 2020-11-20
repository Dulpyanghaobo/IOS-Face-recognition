//
//  Utils.m
//  TestFramework
//
//  Created by yhb on 2020/11/20.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import "Utils.h"



@implementation Utils


+ (CVPixelBufferRef)bytesToPixelBuffer:(size_t)width
                                height:(size_t)height
                                format:(FourCharCode)format
                           baseAddress:(void *)baseAddress
                           bytesPerRow:(size_t)bytesPerRow {
  CVPixelBufferRef pxBuffer = NULL;
  CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, format, baseAddress, bytesPerRow,
                               NULL, NULL, NULL, &pxBuffer);
  return pxBuffer;
}


+ (CVPixelBufferRef)planarBytesToPixelBuffer:(size_t)width
                                      height:(size_t)height
                                      format:(FourCharCode)format
                                 baseAddress:(void *)baseAddress
                                    dataSize:(size_t)dataSize
                                  planeCount:(size_t)planeCount
                                   planeData:(NSArray *)planeData {
  size_t widths[planeCount];
  size_t heights[planeCount];
  size_t bytesPerRows[planeCount];

  void *baseAddresses[planeCount];
  baseAddresses[0] = baseAddress;

  size_t lastAddressIndex = 0;  // Used to get base address for each plane
  for (int i = 0; i < planeCount; i++) {
    NSDictionary *plane = planeData[i];

    NSNumber *width = plane[@"width"];
    NSNumber *height = plane[@"height"];
    NSNumber *bytesPerRow = plane[@"bytesPerRow"];

    widths[i] = width.unsignedLongValue;
    heights[i] = height.unsignedLongValue;
    bytesPerRows[i] = bytesPerRow.unsignedLongValue;

    if (i > 0) {
      size_t addressIndex = lastAddressIndex + heights[i - 1] * bytesPerRows[i - 1];
      baseAddresses[i] = baseAddress + addressIndex;
      lastAddressIndex = addressIndex;
    }
  }

  CVPixelBufferRef pxBuffer = NULL;
  CVPixelBufferCreateWithPlanarBytes(kCFAllocatorDefault, width, height, format, NULL, dataSize,
                                     planeCount, baseAddresses, widths, heights, bytesPerRows, NULL,
                                     NULL, NULL, &pxBuffer);

  return pxBuffer;
}

@end

