//
//  OpencvCameraViewController.m
//  TestFramework
//
//  Created by yhb on 2020/11/19.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import "OpencvCameraViewController.h"
/** 人脸检测*/
#include <SeetaFaceDetector600/seeta/FaceDetector.h>
/** 人脸关键点检测*/
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
/** 人脸识别*/
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
/** 脸部追踪*/
#include <SeetaFaceTracking600/seeta/FaceTracker.h>

//活体检测
#include <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>

// OpenCV2
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/highgui/ios.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIAlertController+Extend.h"
#import "UIImage+Extend.h"
#import "excards.h"
#import "RectManager.h"
#import "SeetaImageModel.h"

#define EHiWeakSelf(type)           __weak typeof(type) weak##type = type;
#define EHiStrongSelf(_instance)    __strong typeof(weak##_instance) _instance = weak##_instance;
//MARK: 描述 -SeetaImageData
//定义结构:图像存储是一个基本数据结构SeetaImageData->对应Opencv当中Mat，基本属性包括图像的宽度和高度，通道数(就是RGB颜色通道)，还有Data
/**
struct SeetaImageData
{
    int width;              // 图像宽度
    int height;             // 图像高度
    int channels;           // 图像通道
    unsigned char *data;    // 图像数据
};
 */
std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
//    构造人脸检测器
seeta::ModelSetting FD_model(buddle + "/assert/model/face_detector.csta");


//     关键点检测器
seeta::ModelSetting FL_model(buddle + "/assert/model/face_landmarker_pts5.csta");
//    简单人脸识别模型
seeta::ModelSetting FR_model(buddle + "/assert/model/face_recognizer_light.csta");
//    活体检验
seeta::ModelSetting FA_model(buddle + "/assert/model/fas_first.csta");

//人脸检测器
seeta::FaceDetector FD(FD_model);
seeta::FaceLandmarker FL(FL_model);
seeta::FaceRecognizer FR(FR_model);
seeta::FaceAntiSpoofing FA(FA_model);
std::shared_ptr<float> featureIdCardWithFace;
std::shared_ptr<float> extract(
                               seeta::FaceRecognizer *fr,
                               const SeetaImageData &image,
                               const std::vector<SeetaPointF> &points) {
    std::shared_ptr<float> features(
                                    new float[fr->GetExtractFeatureSize()],
                                    std::default_delete<float[]>());
    fr->Extract(image, points.data(), features.get());
    return features;
}
//MARK: 描述:活体检测 -antiSpoof
//创建活体检测对象


@interface OpencvCameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>
//------------------  视图  ---------------------
//------------------  数据  ---------------------
// 摄像头设备
@property (nonatomic,strong) AVCaptureDevice *device;
//负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *mCaptureSession;
//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDeviceInput *mCaptureDeviceInput;
//输出设备
@property (nonatomic, strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput;
// 元数据（用于人脸识别）
@property (nonatomic,strong) AVCaptureMetadataOutput *metadataOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

//处理队列
@property (nonatomic, strong) dispatch_queue_t mProcessQueue;


/** 第一次开始请求几个数据组 */
@property (nonatomic, strong) dispatch_queue_t startFaceVerifyGroup;

@property (nonatomic,strong) NSMutableArray *sum;

/** 单次识别率在0.6以上*/
@property (nonatomic, assign) float singleSmailty;
/** 是否通过验证*/
@property (nonatomic, assign) BOOL isPassVerify;

@property (nonatomic,strong) NSNumber *outPutSetting;

// 是否打开手电筒
@property (nonatomic,assign,getter = isTorchOn) BOOL torchOn;
// 人脸检测框区域
@property (nonatomic,assign) CGRect faceDetectionFrame;

//@property (nonatomic, assign) float simmarly;
@property (nonatomic,strong) NSTimer *timer;


@end

@implementation OpencvCameraViewController
/** SeetaImageData转换 **/
STD_API(SeetaImageData) EXCARDS_RecoUnsignedCharData( int nWidth, int nHeight,int channels,unsigned char *ImageData) {
    SeetaImageData img;
    img.height = nHeight;
    img.width = nWidth;
    img.channels = channels;
    img.data = ImageData;
    return img;
}
/** 获取人脸特征进行相似度对比*/
- (std::shared_ptr<float>) EXCARDS_feature:(cv::Mat) cvimage{
    SeetaImageData cvimg = EXCARDS_RecoUnsignedCharData(cvimage.cols, cvimage.rows,cvimage.channels(),cvimage.data);
    auto faces = FD.detect_v2(cvimg);
    if (faces.empty()) {
        NSLog(@"未检测到人脸");
    }
    auto face = faces[0];
    auto facePos = face.pos;
    auto points = FL.mark(cvimg, facePos);
    std::shared_ptr<float> feature = extract(&FR, cvimg, points);
    featureIdCardWithFace = feature;
    return feature;
}
//MARK: 描述 对图像通道进行处理，seetaimagdata只能识别通道数为3的图像
- (cv::Mat)convertTo3Channels:(cv::Mat &)cvimg {
    cv::Mat three_channel = cv::Mat::zeros(cvimg.rows,cvimg.cols,CV_8UC3);
    cv::vector<cv::Mat> channels;
    cv::split(cvimg, channels);
    if (channels.size() <= 3) {
        return cvimg;
    }
    cv::Mat channel1 = channels.at(0);
    cv::Mat channel2 = channels.at(1);
    cv::Mat channel3 = channels.at(2);
    cv::vector<cv::Mat> newChannels;
    newChannels = {channel1,channel2,channel3};
    cv::merge(newChannels, three_channel);
    return three_channel;
}
//MARK: 描述 将身份证UIImage转换成cv::mat
- (cv::Mat)imageToCVMat:(UIImage *)image {
    cv::Mat cvimg;
    UIImageToMat(image, cvimg);
    cv::Mat imgCopy = cv::Mat(cvimg.rows,cvimg.cols,cvimg.depth());
    transpose(cvimg, imgCopy);
    flip(imgCopy,imgCopy,1);
    cv::Mat cvImg_channels = [self convertTo3Channels:cvimg];
    return cvImg_channels;
}

/** 对原图像进行压缩*/
- (cv::Mat)OpencvOrientImageCompression:(cv::Mat)OrientCvImage {
    return OrientCvImage;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // 添加关闭按钮
    [self addCloseButton];
    // 添加计时器(如果10秒内没有检测出结果则退出)
    self.timer = [[NSTimer alloc]init];
    self.timer = [NSTimer timerWithTimeInterval:15.0 target:self selector:@selector(back) userInfo:nil repeats:YES];
       
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    /** 添加PreviewLayer*/
    [self.view.layer addSublayer:self.videoPreviewLayer];

    // 添加rightBarButtonItem为打开／关闭手电筒
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(turnOnOrOffTorch)];
}
- (void)back {
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"未识别成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
    
}

#pragma mark previewLayer
-(AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    if (_videoPreviewLayer == nil) {
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.mCaptureSession];
        
        _videoPreviewLayer.frame = self.view.frame;
        _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    
    return _videoPreviewLayer;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 将AVCaptureViewController的navigationBar调为不透明
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:1];
    [self.mCaptureSession stopRunning];
}
- (void)dealloc {
    [self.view.layer removeFromSuperlayer];
}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
#pragma mark 从输出的元数据中捕捉人脸
// 检测人脸是为了获得“人脸区域”，做“人脸区域”的区域对比
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        
        AVMetadataObject *transformedMetadataObject = [self.videoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        CGRect faceRegion = transformedMetadataObject.bounds;
        
        if (metadataObject.type == AVMetadataObjectTypeFace) {
            if (faceRegion.size.height >0 && faceRegion.size.width >0) {
                
                // 为videoDataOutput设置代理，程序就会自动调用下面的代理方法，捕获每一帧图像
                if (!self.mCaptureDeviceOutput.sampleBufferDelegate) {
                    [self.mCaptureDeviceOutput setSampleBufferDelegate:self queue:self.mProcessQueue];
                }
            }
        }
}
}

//视频采集方法
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]] || [self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if ([output isEqual:self.mCaptureDeviceOutput]) {
            // 身份证信息识别
            [self faceRecongnit:imageBuffer];
            if (self.mCaptureDeviceOutput.sampleBufferDelegate) {
                [self.mCaptureDeviceOutput setSampleBufferDelegate:nil queue:self.mProcessQueue];
            }
        }
    } else {
        NSLog(@"输出格式不支持");
    }
    }
- (cv::Mat)faceImageToCVMat:(UIImage *)img {
    cv::Mat cvimg;
    UIImageToMat(img, cvimg);
//           转换图像通道
    cv::Mat cvImg_channels = [self convertTo3Channels:cvimg];
    cv::Mat imgCopy = cv::Mat(cvimg.rows,cvimg.cols,cvimg.depth());
    transpose(cvImg_channels, imgCopy);
    flip(imgCopy,imgCopy,1);
    return imgCopy;
}
- (void)faceRecongnit:(CVImageBufferRef)imageBuffer {
//保留相同的Core Video缓冲区
    CVBufferRetain(imageBuffer);
//    锁住像素缓冲区
        if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
            UIImage *imgs = [self sampleBufferToImage:imageBuffer];
            cv::Mat cvimg;
            UIImageToMat(imgs, cvimg);
//           转换图像通道
            cv::Mat cvImg_channels = [self convertTo3Channels:cvimg];
            cv::Mat imgCopy = cv::Mat(cvimg.rows,cvimg.cols,cvimg.depth());
            transpose(cvImg_channels, imgCopy);
            flip(imgCopy,imgCopy,1);
//            cv::Mat imgCopy = [self faceImageToCVMat:imgs];
//            进行活体检测
            SeetaImageData img;
            img.width = imgCopy.cols;
            img.height = imgCopy.rows;
            img.channels = imgCopy.channels();
            img.data = imgCopy.data;
            auto faces = FD.detect_v2(img);
            if (faces.empty()) {
                //    解锁像素缓冲区
                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            //    释放缓冲区
                CVBufferRelease(imageBuffer);
                return;
            }
            auto face = faces[0];
            auto facePos = face.pos;
            auto points = FL.mark(img, facePos);
            auto status = FA.PredictVideo(img, facePos, points.data());
            switch (status) {
                    case seeta::FaceAntiSpoofing::Status::REAL:
                    /** 真脸*/
                        self.spoofStatus = FaceVerifyAnitSpoofStatusReal;
                    NSLog(@"真脸");
                        break;
                    case seeta::FaceAntiSpoofing::Status::FUZZY:
                    /** 模糊不清*/
                        self.spoofStatus = FaceVerifyAnitSpoofStatusUnVerify;
                    NSLog(@"模糊不清");
                        break;
                    case seeta::FaceAntiSpoofing::Status::SPOOF:
                /** 假脸*/
                    self.spoofStatus = FaceVerifyAnitSpoofStatusFake;
                    NSLog(@"为假脸");
                    break;
                    case seeta::FaceAntiSpoofing::Status::DETECTING:
                    /** 正在检测*/
                    NSLog(@"正在检测");
                    self.spoofStatus = FaceVerifyAnitSpoofStatusDetecting;
                        break;
                    default:
                        break;
                }
            if (self.spoofStatus == FaceVerifyAnitSpoofStatusFake) {
                [self doRotationOperation:imgCopy];
                //    解锁像素缓冲区
                CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            //    释放缓冲区
                CVBufferRelease(imageBuffer);
                return;
            }
            
            [self doRotationOperation:imgCopy];
        }
    //    解锁像素缓冲区
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    释放缓冲区
    CVBufferRelease(imageBuffer);

}



- (void)doRotationOperation:(cv::Mat)image {
    SeetaImageData faceImg;
    faceImg.width = image.cols;
    faceImg.height = image.rows;
    faceImg.channels = image.channels();
    faceImg.data = image.data;
    if (image.channels()!= 3) {
        return;
    }
    auto faces = FD.detect_v2(faceImg);
    auto face = faces[0];
    auto facePos = face.pos;
    auto pointFace = FL.mark(faceImg, facePos);
    cv::Mat cvimg = [self cvMatFromUIImageIdCard:self.IdCardImg];
    std::shared_ptr<float> featureIdCard = featureIdCardWithFace;
    std::shared_ptr<float> featurecompare = extract(&FR, faceImg, pointFace);
    float simalityFl = FR.CalculateSimilarity(featurecompare.get(), featureIdCard.get());
    NSLog(@"%f",simalityFl);
    [self.sum addObject:@(simalityFl)];
    if (self.spoofStatus == FaceVerifyAnitSpoofStatusReal) {
        BOOL isPassVerify = [self isPassVerifyDetectAndSpoof:simalityFl];
        if ([self.mCaptureSession isRunning]) {
            [self.mCaptureSession stopRunning];
        }
        if (self.SelectedCallBack) {
            self.SelectedCallBack(isPassVerify);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }else if (self.spoofStatus == FaceVerifyAnitSpoofStatusFake){
        BOOL isPassVerify = [self isPassVerifyDetectAndSpoof:simalityFl];
        if ([self.mCaptureSession isRunning]) {
            [self.mCaptureSession stopRunning];
        }
        if (self.SelectedCallBack) {
            self.SelectedCallBack(isPassVerify);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}






//获取人脸位点与关键点
- (void)getFaceLocation:(NSValue *)imageValue {
    SeetaImageData img;
    [imageValue getValue:& img];
    

    auto faces = FD.detect_v2(img);
    if (faces.empty()) {
            return;
    }

}

- (float)complaeteFloat:(NSMutableArray *)sum {
    __block float b = 0.0;
    [sum enumerateObjectsUsingBlock:^(NSNumber * _Nonnull num ,NSUInteger idx,BOOL * _Nonnull stop){
        float a = [num floatValue];
        b += a;
    }];
    float c = b/sum.count;
    NSLog(@"%f",c);
    return  c;
}

-(void)alertControllerWithTitle:(NSString *)title message:(NSString *)message okAction:(UIAlertAction *)okAction cancelAction:(UIAlertAction *)cancelAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message okAction:okAction cancelAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 懒加载

-(UIImage *)sampleBufferToImage:(CVImageBufferRef)imageBuffer{
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    UIImage *result = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(videoImage);
    NSData *data = UIImagePNGRepresentation(result);
    UIImage *image = [[UIImage alloc]initWithData:data];
    return image;
    
}
- (NSMutableArray *)sum {
    if (!_sum) {
        _sum = [NSMutableArray array];
    }
    return _sum;
}
- (AVCaptureSession *)mCaptureSession {
    if (!_mCaptureSession) {
        _mCaptureSession = [[AVCaptureSession alloc]init];
        _mCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
        // 2、设置输入：由于模拟器没有摄像头，因此最好做一个判断
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        
        if (error) {
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [self alertControllerWithTitle:@"没有摄像设备" message:error.localizedDescription okAction:okAction cancelAction:nil];
        }else {
            if ([_mCaptureSession canAddInput:input]) {
                [_mCaptureSession addInput:input];
            }
            
            if ([_mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
                [_mCaptureSession addOutput:self.mCaptureDeviceOutput];
            }
            if ([_mCaptureSession canAddOutput:self.metadataOutput]) {
                [_mCaptureSession addOutput:self.metadataOutput];
                // 输出格式要放在addOutPut之后，否则奔溃
                self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
            }
        }
    }
        return _mCaptureSession;
}
#pragma mark videoDataOutput
-(AVCaptureVideoDataOutput *)mCaptureDeviceOutput {
    if (_mCaptureDeviceOutput == nil) {
        _mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        _mCaptureDeviceOutput.alwaysDiscardsLateVideoFrames = YES;
        _mCaptureDeviceOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:self.outPutSetting};
    }
    
    return _mCaptureDeviceOutput;
}
#pragma mark metadataOutput
-(AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        
        [_metadataOutput setMetadataObjectsDelegate:self queue:self.mProcessQueue];
    }
    
    return _metadataOutput;
}
#pragma mark device
-(AVCaptureDevice *)device {
    if (_device == nil) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        //3.获取摄像头设备(前置摄像头设备)
        //循环设备数组,找到前置摄像头.设置为当前inputCamera
        for (AVCaptureDevice *device in devices) {
            if ([device position] == AVCaptureDevicePositionFront) {
                _device = device;
            }
        }
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            if ([_device isSmoothAutoFocusSupported]) {// 平滑对焦
                _device.smoothAutoFocusEnabled = YES;
            }
            
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {// 自动持续对焦
                _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }
            
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ]) {// 自动持续曝光
                _device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }
            
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {// 自动持续白平衡
                _device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
            
            [_device unlockForConfiguration];
        }
    }
    
    return _device;
}
-(NSNumber *)outPutSetting {
    if (_outPutSetting == nil) {
        _outPutSetting = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    }
    
    return _outPutSetting;
}

#pragma mark - 打开／关闭手电筒
-(void)turnOnOrOffTorch {
    self.torchOn = !self.isTorchOn;
    
    if ([self.device hasTorch]){ // 判断是否有闪光灯
        [self.device lockForConfiguration:nil];// 请求独占访问硬件设备
        
        if (self.isTorchOn) {
            self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"nav_torch_on"] originalImage];
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
            self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"nav_torch_off"] originalImage];
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        [self.device unlockForConfiguration];// 请求解除独占访问硬件设备
    }else {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [self alertControllerWithTitle:@"提示" message:@"您的设备没有闪光设备，不能提供手电筒功能，请检查" okAction:okAction cancelAction:nil];
    }
}

#pragma mark queue
-(dispatch_queue_t)mProcessQueue {
    if (_mProcessQueue == nil) {
//        _queue = dispatch_queue_create("AVCaptureSession_Start_Running_Queue", DISPATCH_QUEUE_SERIAL);
        _mProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    return _mProcessQueue;
}

#pragma mark - 运行session
// session开始，即输入设备和输出设备开始数据传递
- (void)runSession {
    if (![self.mCaptureSession isRunning]) {
        dispatch_async(self.mProcessQueue, ^{
            [self.mCaptureSession startRunning];
            NSLog(@"开始识别");
        });
    }
}
// session停止，即输入设备和输出设备结束数据传递
-(void)stopSession {
    if ([self.mCaptureSession isRunning]) {
        dispatch_async(self.mProcessQueue, ^{
            [self.mCaptureSession stopRunning];
            NSLog(@"停止识别");

        });
    }
}
#pragma mark - view即将出现时
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.currentLight = [[UIScreen mainScreen] brightness];
    [[UIScreen mainScreen] setBrightness:1];
    cv::Mat mat = [self cvMatFromUIImageIdCard:self.IdCardImg];
    [self EXCARDS_feature:mat];
    // 将AVCaptureViewController的navigationBar调为透明
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:0];
    [self checkAuthorizationStatus];
    
    // rightBarButtonItem设为原样
    self.torchOn = NO;
    self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"nav_torch_off"] originalImage];
}
#pragma mark - 检测摄像头权限
-(void)checkAuthorizationStatus {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:[self showAuthorizationNotDetermined]; break;// 用户尚未决定授权与否，那就请求授权
        case AVAuthorizationStatusAuthorized:[self showAuthorizationAuthorized]; break;// 用户已授权，那就立即使用
        case AVAuthorizationStatusDenied:[self showAuthorizationDenied]; break;// 用户明确地拒绝授权，那就展示提示
        case AVAuthorizationStatusRestricted:[self showAuthorizationRestricted]; break;// 无法访问相机设备，那就展示提示
        }
}
#pragma mark - 相机使用权限处理
#pragma mark 用户还未决定是否授权使用相机
-(void)showAuthorizationNotDetermined {
    __weak __typeof__(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        granted? [weakSelf runSession]: [weakSelf showAuthorizationDenied];
    }];
}

#pragma mark 被授权使用相机
-(void)showAuthorizationAuthorized {
    [self runSession];
}

#pragma mark 未被授权使用相机
-(void)showAuthorizationDenied {
    NSString *title = @"相机未授权";
    NSString *message = @"请到系统的“设置-隐私-相机”中授权此应用使用您的相机";
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到该应用的隐私设授权置界面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];

    [self alertControllerWithTitle:title message:message okAction:okAction cancelAction:cancelAction];
}

#pragma mark 使用相机设备受限
-(void)showAuthorizationRestricted {
    NSString *title = @"相机设备受限";
    NSString *message = @"请检查您的手机硬件或设置";
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [self alertControllerWithTitle:title message:message okAction:okAction cancelAction:nil];
}
#pragma mark - 添加关闭按钮
-(void)addCloseButton {
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [closeBtn setImage:[UIImage imageNamed:@"idcard_back"] forState:UIControlStateNormal];
    CGFloat closeBtnWidth = 40;
    CGFloat closeBtnHeight = closeBtnWidth;
    CGRect viewFrame = self.view.frame;
    closeBtn.frame = (CGRect){CGRectGetMaxX(viewFrame) - closeBtnWidth, CGRectGetMaxY(viewFrame) - closeBtnHeight, closeBtnWidth, closeBtnHeight};
    
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:closeBtn];
}
//MARK: 描述 - 判断结果
-(BOOL)isPassVerifyDetectAndSpoof:(float)samiltay {
    if (samiltay > 0.20) {
        return true;
    }else{
        return false;
    }
}
#pragma mark 绑定“关闭按钮”的方法
-(void)close {
    [self.navigationController popViewControllerAnimated:YES];
}
-(cv::Mat)cvMatFromUIImageIdCard:(UIImage *)image {
    cv::Mat cvImg = [self imageToCVMat:image];
    return  cvImg;
}
//获取照片进行本地转换
- (std::string *)getImagePathIdCard:(UIImage *)image {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/2.jpg"];   // 保存文件的名称
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
