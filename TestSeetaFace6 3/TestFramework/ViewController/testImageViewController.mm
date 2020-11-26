//
//  testImageViewController.m
//  TestFramework
//
//  Created by yhb on 2020/11/26.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import "testImageViewController.h"
/** 人脸检测*/
#include <SeetaFaceDetector600/seeta/FaceDetector.h>
/** 人脸关键点检测*/
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
/** 人脸识别*/
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
// OpenCV2
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/highgui/ios.h>
#import "UIAlertController+Extend.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "excards.h"
std::string buddles = [[[NSBundle mainBundle] resourcePath] UTF8String];
//    构造人脸检测器
seeta::ModelSetting FD_models(buddles + "/assert/model/face_detector.csta");


//     关键点检测器
seeta::ModelSetting FL_models(buddles + "/assert/model/face_landmarker_pts5.csta");
//    简单人脸识别模型
seeta::ModelSetting FR_models(buddles + "/assert/model/face_recognizer_light.csta");


//人脸检测器
seeta::FaceDetector FDs(FD_models);
seeta::FaceLandmarker FLs(FL_models);
seeta::FaceRecognizer FRs(FR_models);
std::shared_ptr<float> featureIdCardWithFaces;
std::shared_ptr<float> extracts(
                               seeta::FaceRecognizer *fr,
                               const SeetaImageData &image,
                               const std::vector<SeetaPointF> &points) {
    std::shared_ptr<float> features(
                                    new float[fr->GetExtractFeatureSize()],
                                    std::default_delete<float[]>());
    fr->Extract(image, points.data(), features.get());
    return features;
}
/** SeetaImageData转换 **/
STD_API(SeetaImageData) EXCARDS_RecoUnsignedCharDatas( int nWidth, int nHeight,int channels,unsigned char *ImageData) {
    SeetaImageData img;
    img.height = nHeight;
    img.width = nWidth;
    img.channels = channels;
    img.data = ImageData;
    return img;
}

@interface testImageViewController ()
@property (nonatomic,strong) NSString *bundles;

@property (nonatomic,strong) NSString *bundlesTestImage;
@end

@implementation testImageViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];


}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bundles =[NSString stringWithFormat:@"%@/assert/Ben_Howland/",[[NSBundle mainBundle] resourcePath]];
//    self.bundles =[NSString stringWithFormat:@"%@/assert/Aaron_Sorkin/",[[NSBundle mainBundle] resourcePath]];
    NSLog(@"%@aligned_detect_0.602.jpg",self.bundles);
    self.bundlesTestImage =[NSString stringWithFormat:@"%@/assert/Aaron_Eckhart/",[[NSBundle mainBundle] resourcePath]];
    cv::Mat mat = cv::imread([[NSString stringWithFormat:@"%@0/aligned_detect_0.602.jpg",self.bundlesTestImage] UTF8String]);
    [self EXCARDS_feature:mat];
    [self showFiles:self.bundles];
}
- (void)showFiles:(NSString *)path {
    // 1.判断文件还是目录
    NSFileManager * fileManger = [NSFileManager defaultManager];

    BOOL isDir = NO;

    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];

    if (isExist) {
        // 2. 判断是不是目录

        if (isDir) {
        NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];

            NSString * subPath = nil;

            for (NSString * str in dirArray) {
                subPath  = [path stringByAppendingPathComponent:str];

                BOOL issubDir = NO;

                 [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];

                [self showFiles:subPath];

            }
        }else{
            NSLog(@"%@",path);
            cv::Mat cvImg = cv::imread([path UTF8String]);
            SeetaImageData img;
            img.height = cvImg.rows;
            img.width = cvImg.cols;
            img.data = cvImg.data;
            img.channels = cvImg.channels();
            if (cvImg.channels()!= 3) {
                return;
            }
            auto faces = FDs.detect_v2(img);
            if (faces.empty()) {
                return;
            }
            auto face = faces[0];
            auto facePos = face.pos;
            auto pointFace = FLs.mark(img, facePos);
            std::shared_ptr<float> featureIdCard = featureIdCardWithFaces;
            std::shared_ptr<float> featurecompare = extracts(&FRs, img, pointFace);
            float simalityFl = FRs.CalculateSimilarity(featurecompare.get(), featureIdCard.get());
            //MARK: 描述-对比分数
            NSLog(@"%f",simalityFl);
        }

    }else{
        NSLog(@"你打印的是目录或者不存在");
    }

}
/** 获取人脸特征进行相似度对比*/
- (std::shared_ptr<float>) EXCARDS_feature:(cv::Mat) cvimage{
    SeetaImageData cvimg = EXCARDS_RecoUnsignedCharDatas(cvimage.cols, cvimage.rows,cvimage.channels(),cvimage.data);
    auto faces = FDs.detect_v2(cvimg);
    if (faces.empty()) {
        NSLog(@"未检测到人脸");
        return featureIdCardWithFaces;
    }
    auto face = faces[0];
    auto facePos = face.pos;
    auto points = FLs.mark(cvimg, facePos);
    std::shared_ptr<float> feature = extracts(&FRs, cvimg, points);
    featureIdCardWithFaces = feature;
    return feature;
}
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
@end
