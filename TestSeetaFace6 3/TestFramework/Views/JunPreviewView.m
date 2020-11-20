//
//  JunPreviewView.m
//  TestFramework
//
//  Created by yhb on 2020/11/17.
//  Copyright © 2020 seetadev. All rights reserved.
//
//处理识别出来的人脸


#import "JunPreviewView.h"

@interface JunPreviewView()

@property (nonatomic,strong) CALayer *overLayer;

@property (nonatomic,strong) NSMutableDictionary<NSString *,id>*faceLayers;
//@property (nonatomic,strong) NSArray<NSDictionary *> *faceLayers;

@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;


@end


@implementation JunPreviewView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor blackColor];
    self.overLayer.frame = self.frame;
    self.overLayer.sublayerTransform = [self CATransform3DMakePerspective:1000];
    [self.layer addSublayer:self.overLayer];
    
}

-(void)handleOutput:(NSArray<AVMetadataObject *>*)faceObject preview:(AVCaptureVideoPreviewLayer *)preview {
    self.previewLayer = preview;
//    获取预览图层的人脸数组
    NSArray<AVMetadataFaceObject *> *transformFaces = [self transformedFaces:faceObject];
//    拷贝一份所有人脸faceId字典
    NSMutableArray<NSString *> *lostFaces = [NSMutableArray array];
    NSArray<NSString *>*faceIds = self.faceLayers.allKeys;
    for (NSString *faceID in faceIds) {
        [lostFaces addObject:faceID];
    }
////    遍历所有face
    [transformFaces enumerateObjectsUsingBlock:^(AVMetadataFaceObject * _Nonnull face ,NSUInteger idx,BOOL * _Nonnull stop){
        if ([lostFaces containsObject:[NSString stringWithFormat:@"%ld",face.faceID]]) {
            [lostFaces removeObjectAtIndex:idx];
        }
        NSString *faceId = [NSString stringWithFormat:@"%ld",face.faceID];
//        获取图层
        CALayer *faceLayer = self.faceLayers[faceId];
        if (faceLayer == nil) {
            faceLayer = [self createFaceLayer];
            //添加到字典中
            [self.overLayer addSublayer:faceLayer];
            [self.faceLayers setValue:faceLayer forKeyPath:faceId];
        }
        //3.3 设置layer属性
        faceLayer.transform = CATransform3DIdentity;
        faceLayer.frame = face.bounds;
        //3.4 设置偏转角(左右摇头)
        if (face.hasYawAngle){
            CATransform3D tranform3D = [self transformDegressYaw:face.yawAngle];
            //矩阵处理
            faceLayer.transform = CATransform3DConcat(faceLayer.transform, tranform3D);
        }
        
        //3.5 设置倾斜角,侧倾角(左右歪头)
        if (face.hasRollAngle){
            CATransform3D tranform3D =[self transformDegressRoll:face.rollAngle];
            
            //矩阵处理
            faceLayer.transform = CATransform3DConcat(faceLayer.transform, tranform3D);
        }
        
        //3.6 移除消失的layer
        for (NSString *faceIDStr in lostFaces){
            CALayer *faceIdLayer = self.faceLayers[faceIDStr];
            [faceIdLayer removeFromSuperlayer];
            [self.faceLayers removeObjectForKey:faceIDStr];
        }
        
    }];
    
}
//人脸进行坐标转换
- (NSArray<AVMetadataFaceObject *> *)transformedFaces:(NSArray<AVMetadataObject *> *)faceObjs {
    NSMutableArray<AVMetadataFaceObject *> *faceArry = [NSMutableArray array];
    for (AVMetadataFaceObject *face in faceObjs) {
        AVMetadataFaceObject *tranface = (AVMetadataFaceObject *)[self.previewLayer transformedMetadataObjectForMetadataObject: face];
        [faceArry addObject:tranface];
    }
    return faceArry;
}

//设置脸部图层
- (CALayer *)createFaceLayer {
    CALayer *layer = [[CALayer alloc]init];
    layer.borderColor = [UIColor redColor].CGColor;
    layer.borderWidth = 3;
    return layer;
}



//处理倾斜角问题
- (CATransform3D)transformDegressYaw:(CGFloat)yawAngle {
    CGFloat yaw = [self degreesToRadians:yawAngle];
    CATransform3D yawTran = CATransform3DMakeRotation(yaw, 0, -1, 0);
    return CATransform3DConcat(yawTran, CATransform3DIdentity);
}

- (CATransform3D)transformDegressRoll:(CGFloat)rollAngle {
    CGFloat roll = [self degreesToRadians:rollAngle];
    return  CATransform3DMakeRotation(roll, 0, 0, 1);
}

//角度转换
- (CGFloat)degreesToRadians:(CGFloat)degress{
    return degress * 3.14/180;
}



- (CATransform3D)CATransform3DMakePerspective:(CGFloat)eyePostition {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / eyePostition;
    return transform;
}
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]init];
    }
    return _previewLayer;
}
@end
