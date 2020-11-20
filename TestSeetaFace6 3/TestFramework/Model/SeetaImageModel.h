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
@property (nonatomic, assign)int width;
@property (nonatomic, assign)int height;
@property (nonatomic, assign)int channels;
@property (nonatomic, strong) NSData *data;
@end

NS_ASSUME_NONNULL_END
