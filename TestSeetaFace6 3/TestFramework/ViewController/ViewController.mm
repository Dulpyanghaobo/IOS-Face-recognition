//
//  ViewController.m
//  TestFramework
//
//  Created by seetadev on 2020/1/6.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import "ViewController.h"
#include <SeetaFaceDetector600/seeta/FaceDetector.h>
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
#include <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>
#include <SeetaEyeStateDetector200/seeta/EyeStateDetector.h>
#include <SeetaMaskDetector200/seeta/MaskDetector.h>
#include <SeetaAgePredictor600/seeta/AgePredictor.h>
#include <SeetaGenderPredictor600/seeta/GenderPredictor.h>
#include <SeetaFaceTracking600/seeta/FaceTracker.h>
#include <SeetaQualityAssessor300/seeta/QualityOfBrightness.h>
#include <SeetaQualityAssessor300/seeta/QualityOfClarity.h>
#include <SeetaQualityAssessor300/seeta/QualityOfIntegrity.h>
#include <SeetaQualityAssessor300/seeta/QualityOfLBN.h>
#include <SeetaQualityAssessor300/seeta/QualityOfPose.h>
#include <SeetaQualityAssessor300/seeta/QualityOfPoseEx.h>
#include <SeetaQualityAssessor300/seeta/QualityOfResolution.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/highgui/ios.h> // OpenCV2

#include <iostream>
#include <fstream>
#import "UIImage+OpenCV.h"
#import "SeetaFaceTracking600/seeta/FaceTracker.h"
#import "Masonry.h"
#import "TZImagePickerController.h"
#import "UIImage+Add.h"
#import "OpencvCameraViewController.h"
#import "SeetaImageModel.h"
//#import <string.h>
#import <string.h>

#include <stdlib.h>
#define EHiWeakSelf(type)           __weak typeof(type) weak##type = type;
#define EHiStrongSelf(_instance)    __strong typeof(weak##_instance) _instance = weak##_instance;
//std::string buddles = [[[NSBundle mainBundle] resourcePath] UTF8String];

////    构造人脸检测器
//seeta::ModelSetting FD_models(buddles + "/assert/model/face_detector.csta");
////     关键点检测器
//seeta::ModelSetting FL_model(buddle + "/assert/model/face_landmarker_pts5.csta");
////    简单人脸识别模型
//seeta::ModelSetting FR_model(buddle + "/assert/model/face_recognizer_light.csta");
////seeta::ModelSetting FR_model(buddle + "/assert/model/SeetaFaceRecognizer6.0.TRIPLE.sta");
////    全局活体检测和局部活体检测
//seeta::ModelSetting FAS_model(std::vector<std::string>({buddle + "/assert/model/fas_first.csta",buddle + "/assert/model/fas_second.csta"}));
//seeta::ModelSetting Traker_model(buddle + "/assert/model/");
//seeta::FaceTracker *Tracker_model();
//seeta::FaceDetector FDs(FD_models);
//seeta::FaceLandmarker FL(FL_model);
//seeta::FaceRecognizer FR(FR_model);
//seeta::FaceAntiSpoofing FAS(FAS_model);
//seeta::EyeStateDetector ESD(seeta::ModelSetting(buddle + "/assert/model/eye_state.csta"));
//seeta::MaskDetector MD(seeta::ModelSetting(buddle + "/assert/model/mask_detector.csta"));
//seeta::AgePredictor AP(seeta::ModelSetting(buddle + "/assert/model/age_predictor.csta"));
//seeta::GenderPredictor GP(seeta::ModelSetting(buddle + "/assert/model/gender_predictor.csta"));

//std::string img_path = buddles + "/assert/6.jpg";


SeetaImageData imgCompare;

cv::vector<cv::Mat> scaledTempls; //各个缩放等级的模板图片矩阵
//static const float resizeRatio = 0.35;     //原图缩放比例，越小性能越好，但识别度越低
//static const int maxTryTimes = 4;          //未达到预定识别度时，再尝试的次数限制
//static const float acceptableValue = 0.7;  //达到此识别度才被认为正确
//static const float scaleRation = 0.75;     //当模板未被识别时，尝试放大/缩小模板。 指定每次模板缩小的比例
__const int h = [[UIScreen mainScreen] bounds].size.height;
__const int w = [[UIScreen mainScreen] bounds].size.width;
@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
//------------------  视图  ---------------------
//界面信息
@property (nonatomic,strong) UIButton *detailDataButton;

//是否通过验证
@property (nonatomic,strong) UILabel *showPassLab;

/** 上传图片处理*/
@property (nonatomic,strong) UIButton *uploadImageButton;

/** 身份证正面照片*/
@property (nonatomic,strong) UIButton *showImage;

/** 身份证背面照片*/
@property (nonatomic,strong) UIButton *backShowImage;

@property (nonatomic,strong) UIButton *IdCardInfoButton;

@property (nonatomic,strong) UIImage *IdcardImage;
@property (nonatomic,strong) SeetaImageModel *model;
//数据
//------------------  数据  ---------------------
//后台传入的图片数据
@property (nonatomic,strong) NSArray<UIImage *> *imageArry;
//@property (nonatomic,strong) CameraViewController *vc;
@property (nonatomic,strong) OpencvCameraViewController *vc;

@end

@implementation ViewController


class PipeStream {
public:
    PipeStream() {}
    
    const std::string str() const {
        return oss.str();
    }
    
    template <typename T>
    PipeStream &operator << (T &&t) {
        oss << std::forward<T>(t);
        return *this;
    }
private:
    std::ostringstream oss;
};

template <typename T, typename ...Args>
void TestQuality(PipeStream &pipe,
                 const std::string &name,
                 const SeetaImageData &image,
                 const SeetaRect &face,
                 const std::vector<SeetaPointF> &points,
                 Args &&...args) {
    
    seeta::QualityRule *qa = new T(std::forward<Args>(args)...);
    static const char *LEVEL[] = {"low", "medium", "high"};
    
    auto result = qa->check(image, face, points.data(), int32_t(points.size()));
    
    pipe << name << ": level=" << LEVEL[int(result.level)] << ", score=" << result.score << "\n";
    
    delete qa;
}


namespace seeta {
    class QualityOfClarityEx : public QualityRule {
    public:
        QualityOfClarityEx(const std::string &lbn, const std::string &marker) {
            m_lbn = std::make_shared<QualityOfLBN>(ModelSetting(lbn));
            m_marker = std::make_shared<FaceLandmarker>(ModelSetting(marker));
        }
        QualityOfClarityEx(const std::string &lbn, const std::string &marker, float blur_thresh) {
            m_lbn = std::make_shared<QualityOfLBN>(ModelSetting(lbn));
            m_marker = std::make_shared<FaceLandmarker>(ModelSetting(marker));
            m_lbn->set(QualityOfLBN::PROPERTY_BLUR_THRESH, blur_thresh);
        }
        
        QualityResult check(const SeetaImageData &image, const SeetaRect &face, const SeetaPointF *points, int32_t N) override {
            // assert(N == 68);
            auto points68 = m_marker->mark(image, face);
            int light, blur, noise;
            m_lbn->Detect(image, points68.data(), &light, &blur, &noise);
            if (blur == QualityOfLBN::BLUR) {
                return {QualityLevel::LOW, 0};
            } else {
                return {QualityLevel::HIGH, 1};
            }
        }
        
    private:
        std::shared_ptr<QualityOfLBN> m_lbn;
        std::shared_ptr<FaceLandmarker> m_marker;
    };
}

//- (void)updateLabel:(const std::string &)str {
//    [self.detailDataButton setText:[NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]]];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setUpUI];
    PipeStream pipe;
    //MARK: 描述-人脸对比
//    auto cvimg = cv::imread(img_path);
//    std::string img_path2 = buddle + "/assert/5.jpg";
//    auto cvImage = cv::imread(img_path2);
//    [self.imageView2 setImage: uiimage];
//    [self.imageView2 setContentMode: UIViewContentModeScaleAspectFit];
//    imgCompare.height = cvImage.rows;
//    imgCompare.width = cvImage.cols;
//    imgCompare.channels = cvImage.channels();
//    imgCompare.data = cvImage.data;
//    self.lab = [[UILabel alloc]init];
//    [self.view addSubview:self.lab];
//    self.lab.frame = CGRectMake(w/2, 90, w/2, 30);
    
//    //  获取图像数据
//    SeetaImageData img;
//    img.height = cvimg.rows;
//    img.width = cvimg.cols;
//    img.channels = cvimg.channels();
//    img.data = cvimg.data;
////
//    auto faces = FDs.detect_v2(img);
//
//    auto faceComapres = FD.detect_v2(imgCompare);
//
//    pipe << "Detected " << faces.size() << " face(s)." << "\n";
//    for (auto &face : faces) {
//        pipe << "    " << "[" << face.pos.x << ", " << face.pos.y << ", "
//        << face.pos.width << ", " << face.pos.height << "]" << "\n";
//    }
//
//    if (faces.empty()) {
//        return;
//    }
//
//    auto face = faces[0];
//    auto faceCompare = faceComapres[0];
//
//    auto points = FL.mark(img, face.pos);
//    auto pointCompare = FL.mark(imgCompare, faceCompare.pos);
//    //    pipe << "Got " << FL.number() << " landmarks on face 0." << "\n";
//    //    pipe << "    " << "[";
//    //    for (size_t i = 0; i < points.size(); ++i) {
//    //        if (i) {
//    //            pipe << "\n" << "     ";
//    //        }
//    //        auto &point = points[i];
//    //        pipe << "(" << point.x << ", " << point.y << ")";
//    //    }
//    //    pipe << "]" << "\n";
//
//    FR.Extract(img, points.data(), features.get());
//    FR.Extract(imgCompare, pointCompare.data(), featureCompare.get());
//    pipe << "Extract " << FR.GetExtractFeatureSize() << " features." << "\n";
//
//    feature = extract(&FR, img, points);
//    std::shared_ptr<float> featurecompare = extract(&FR, imgCompare, pointCompare);
//    //    float  Similarity = FR->CalculateSimilarity(feat1.get(), feat2.get()
//    float simality = FR.CalculateSimilarity(features.get(), featurecompare.get());
//    pipe << "simality:"<<simality<<"\n";
//    auto status = FAS.Predict(img, face.pos, points.data());
//    if (simality >= 0.3) {
//        self.lab.text = @"验证已通过";
//    }else {
//        self.lab.text =@"验证未通过";
//    }
//    switch (status) {
//        case seeta::FaceAntiSpoofing::Status::REAL:
//            pipe << "FAS: real" << "\n";
//            break;
//        case seeta::FaceAntiSpoofing::Status::SPOOF:
//            pipe << "FAS: spoof" << "\n";
//            break;
//        case seeta::FaceAntiSpoofing::Status::FUZZY:
//            pipe << "FAS: fuzzy" << "\n";
//            break;
//        case seeta::FaceAntiSpoofing::Status::DETECTING:
//            pipe << "FAS: detecting" << "\n";
//            break;
//        default:
//            break;
//    }
//
//    float clarity, reality;
//    FAS.GetPreFrameScore(&clarity, &reality);
//
//    pipe << "FAS: clarity=" << clarity << ", reality=" << reality << "\n";
//
//    seeta::EyeStateDetector::EYE_STATE left_eye, right_eye;
//    const char *EYE_STATE_STR[] = {"close", "open", "fuzzy", "unknown"};
//    ESD.Detect(img, points.data(), left_eye, right_eye);
//
//    pipe << "Eyes: (" << EYE_STATE_STR[left_eye] << ", "
//    << EYE_STATE_STR[right_eye] << ")" << "\n";
//
//    bool mask = MD.detect(img, face.pos);
//
//    pipe << "Mask: " << std::boolalpha << mask << "\n";
//
//    int age = 0;
//    AP.PredictAgeWithCrop(img, points.data(), age);
//
//    pipe << "Age: " << age << "\n";
//
//    seeta::GenderPredictor::GENDER gender;
//    const char *GENDER_STR[] = {"male", "female"};
//    GP.PredictGenderWithCrop(img, points.data(), gender);
//
//    pipe << "Gender: " << GENDER_STR[int(gender)] << "\n";
//
//
//    seeta::FaceTracker FT(seeta::ModelSetting(buddle + "/assert/model/face_detector.csta"),
//                          img.width, img.height);
//
//    auto ctracked_faces = FT.Track(img);
//    auto tracked_faces = std::vector<SeetaTrackingFaceInfo>(ctracked_faces.data, ctracked_faces.data + ctracked_faces.size);
//
//    //    pipe << "Tracked " << faces.size() << " face(s)." << "\n";
//    //    for (auto &face : tracked_faces) {
//    //        pipe << "    " << "[" << face.pos.x << ", " << face.pos.y << ", "
//    //                  << face.pos.width << ", " << face.pos.height << "]"
//    //                  << " PID = " << face.PID
//    //                  << "\n";
//    //    }
//
//    //    pipe << "QualityOf:" << "\n";
//    //
//    //    TestQuality<seeta::QualityOfBrightness>(pipe, "    Brightness", img, face.pos, points);
//    //    TestQuality<seeta::QualityOfClarity>(pipe, "    Clarity", img, face.pos, points);
//    //    TestQuality<seeta::QualityOfIntegrity>(pipe, "    Integrity", img, face.pos, points);
//    //    TestQuality<seeta::QualityOfClarityEx>(pipe, "    ClarityEx", img, face.pos, points,
//    //                                           buddle + "/assert/model/quality_lbn.csta",
//    //                                           buddle + "/assert/model/face_landmarker_pts68.csta");
//    //    TestQuality<seeta::QualityOfPose>(pipe, "    Pose", img, face.pos, points);
//    //    TestQuality<seeta::QualityOfPoseEx>(pipe, "    PoseEx", img, face.pos, points,
//    //                                        seeta::ModelSetting(buddle + "/assert/model/pose_estimation.csta"));
//    //    TestQuality<seeta::QualityOfResolution>(pipe, "    Resolution", img, face.pos, points);
//    //
//    //    pipe << "Every thing's OK" << "\n";
//
//    [self updateLabel:pipe.str()];
    
    
}
//std::shared_ptr<float> extract(
//                               seeta::FaceRecognizer *fr,
//                               const SeetaImageData &image,
//                               const std::vector<SeetaPointF> &points) {
//    std::shared_ptr<float> features(
//                                    new float[fr->GetExtractFeatureSize()],
//                                    std::default_delete<float[]>());
//    fr->Extract(image, points.data(), features.get());
//    return features;
//}
//MARK: 描述 -delegate

- (void)pickerFormLibray {
    TZImagePickerController *imagePickerVC = [[TZImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:4 delegate:nil];
    
    imagePickerVC.maxImagesCount = 1;
    imagePickerVC.isSelectOriginalPhoto = NO;
    imagePickerVC.allowPickingOriginalPhoto = NO;
    imagePickerVC.allowPickingVideo = NO;
    imagePickerVC.allowTakeVideo = NO;
    imagePickerVC.showPhotoCannotSelectLayer = YES;
    
//    imagePickerVC.allowCrop = YES;
//    imagePickerVC.needCircleCrop = YES;
    
    imagePickerVC.cannotSelectLayerColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    imagePickerVC.oKButtonTitleColorNormal = [UIColor whiteColor];
    imagePickerVC.oKButtonTitleColorDisabled = [UIColor whiteColor];
    imagePickerVC.iconThemeColor = [UIColor greenColor];
    
    UIImage *selectedImage = [UIImage imageWithColor:[UIColor greenColor] size:CGSizeMake(24, 24)];
    selectedImage = [selectedImage imageByRoundCornerRadius:12];
    imagePickerVC.photoSelImage = selectedImage;

    EHiWeakSelf(self)
    [imagePickerVC setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        EHiStrongSelf(self)
        [self selectedImage:photos.firstObject];
    }];
    [self.navigationController presentViewController:imagePickerVC animated:nil completion:nil];
}
- (void)selectedImage:(UIImage *)photos {
    [self.showImage setImage:photos forState:UIControlStateNormal];
    self.IdcardImage = photos;
    cv::Mat mat = [self cvMatFromUIImage:self.IdcardImage];
    [self IdCardDetect:mat];
}
-(cv::Mat)cvMatFromUIImage:(UIImage *)image {
    
     
//    UIImage* MatToUIImage(const cv::Mat& image);
//    void UIImageToMat(const UIImage* image,
//                             cv::Mat& m, bool alphaExist = false);
    
    
//    cv::Mat cvimg = [self CVMat:image];
    std::string *filePath = [self getImagePath:image];
    
    cv::Mat cvImg = cv::imread(filePath->c_str());
    
//    cv::Mat cvImg = cv::imread(img_path);

    cv::Mat imgCopy = cv::Mat(cvImg.rows,cvImg.cols,cvImg.depth());
    transpose(cvImg, imgCopy);
    flip(imgCopy, imgCopy, 0);  //rotate 90
    UIImageToMat(image, cvImg);

    UIImage *image222 =MatToUIImage(imgCopy);
    return  imgCopy;
}

//获取照片进行本地转换
- (std::string *)getImagePath:(UIImage *)image {
    
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
- (void)IdCardDetect:(cv::Mat)cvimag {
        struct SeetaImageData img;
        img.height = cvimag.rows;
        img.width = cvimag.cols;
        img.channels = cvimag.channels();
        img.data = cvimag.data;
//    auto faces = FDs.detect_v2(img);
    self.model = [[SeetaImageModel alloc]init];
    self.model.height = img.height;
    self.model.width = img.width;
    self.model.channels = img.channels;


    NSLog(@"demp");
}
int getLen(const unsigned char s[])
{
int nLen = 0;
const unsigned char* p = s;
while(*p!=0){
nLen++;
p++;
}
return nLen;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}
- (OpencvCameraViewController *)vc {
    if (!_vc) {
        _vc = [[OpencvCameraViewController alloc]init];
            EHiWeakSelf(self)
            _vc.SelectedCallBack = ^(BOOL isSuccess) {
                EHiStrongSelf(self)
                dispatch_async(dispatch_get_main_queue(), ^{
                if (isSuccess) {
                    self.showPassLab.text = @"通过验证";
                }else {
                    self.showPassLab.text = @"未通过验证";
                }
                });
            };
        }
    return  _vc;
}
- (float)complaeteFloat:(NSMutableArray *)sum {
    __block float b = 0.0;
    [sum enumerateObjectsUsingBlock:^(NSNumber * _Nonnull num ,NSUInteger idx,BOOL * _Nonnull stop){
        float a = [num floatValue];
        b += a;
    }];
    float c = b/sum.count;
    return  c;
}
//-(float)simarity:(UIImage *)image {
//    //    cv::Mat cvImage;
//    //    UIImageToMat(image, cvImage);
//    //    cv::cvConvert(cvImage, CV_32FC3);
//    
//    //MARK: 描述-人脸对比
//    auto cvImg = cv::imread(img_path);
//    auto cvimg = [self cvMatFromUIImage:image];
//    SeetaImageData img;
//    img.height = cvimg.rows;
//    img.width = cvimg.cols;
//    img.channels = cvimg.channels();
//    img.data = cvimg.data;
//    SeetaImageData ImgIdCard;
//    ImgIdCard.height = cvImg.rows;
//    ImgIdCard.width =cvImg.cols;
//    ImgIdCard.channels = cvImg.channels();
//    ImgIdCard.data = cvImg.data;
//    auto faceComapres = FD.detect_v2(img);
//    auto faceIdcards = FD.detect_v2(ImgIdCard);
//    if (faceComapres.size() == 0 || faceIdcards.size() == 0) {
//        return 0.0;
//    }
//    
//    auto faceCompare = faceComapres[0];
//    auto faceIdCard = faceIdcards[0];
//    auto pointCompare = FL.mark(img, faceCompare.pos);
//    auto pointIdCard = FL.mark(ImgIdCard, faceIdCard.pos);
//    std::unique_ptr<float[]> featureCompare(new float[FR.GetExtractFeatureSize()]);
//    std::unique_ptr<float[]> featureIdcard(new float[FR.GetExtractFeatureSize()]);
//    
//    FR.Extract(img, pointCompare.data(), featureCompare.get());
//    FR.Extract(ImgIdCard, pointIdCard.data(), featureIdcard.get());
//    
//    std::shared_ptr<float> featurecompare = extract(&FR, img, pointCompare);
//    std::shared_ptr<float> featureIdCard = extract(&FR, ImgIdCard, pointIdCard);
//    
//    float simalityFl = FR.CalculateSimilarity(featureIdCard.get(), featurecompare.get());
//    
//    return simalityFl;
//}

- (void)p_setUpUI {
    [self.view addSubview:self.uploadImageButton];
    [self.view addSubview:self.detailDataButton];
    [self.view addSubview:self.showPassLab];
    [self.view addSubview:self.showImage];
    [self.view addSubview:self.backShowImage];
    [self.view addSubview:self.IdCardInfoButton];
    [self add_Masrony];
}
- (void) add_Masrony {
    [self.uploadImageButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.height.mas_equalTo(52);
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.bottom.mas_offset(-20);
    }];
    [self.detailDataButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.height.mas_equalTo(30);
        make.bottom.equalTo(self.uploadImageButton.mas_top).offset(-18);
    }];
    [self.IdCardInfoButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.bottom.equalTo(self.detailDataButton.mas_top).offset(-18);
        make.height.mas_equalTo(20);
    }];
    [self.showPassLab mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.centerX.equalTo(self.IdCardInfoButton);
        make.bottom.equalTo(self.IdCardInfoButton.mas_top).offset(-18);
        make.height.mas_equalTo(42);
    }];

    [self.showImage mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.mas_offset(100);
        make.height.mas_equalTo(92);
    }];
    [self.backShowImage mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.showImage.mas_bottom).offset(12);
        make.height.mas_equalTo(92);
    }];

}
//MARK: 描述 - event
- (void)getDetailData {
    
}

- (void)didClickIt {
        //MARK: 描述
//        struct SeetaImageData IdCardImg02;
//        [self.IdcardSeetaData getValue:& IdCardImg02];
    if (self.IdcardImage) {
        self.vc.IdCardImg = self.IdcardImage;
        [self.navigationController pushViewController:self.vc animated:NO];
    } else {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"抱歉为检测到你上传身份证"
                                                                                     message:@"请重新上传"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
        [self.navigationController presentViewController:alertController animated:false completion:nil];
    }
}
- (void)getDetailIdCardInfo {
    
}
//MARK: 描述 -event
- (void)checkItImage {
    NSLog(@"点击上传身份证正面");
    [self pickerFormLibray];
}
//MARK: 描述 - getter
- (UIButton *)uploadImageButton {
    if (!_uploadImageButton) {
        _uploadImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_uploadImageButton setTitle:@"人脸识别" forState:UIControlStateNormal];
        _uploadImageButton.layer.cornerRadius = 12;
        _uploadImageButton.backgroundColor = [UIColor yellowColor];
        [_uploadImageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_uploadImageButton addTarget:self action:@selector(didClickIt) forControlEvents:UIControlEventTouchUpInside];
    }
    return _uploadImageButton;
}
- (UIButton *)detailDataButton {
    if (!_detailDataButton) {
        _detailDataButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_detailDataButton setTitle:@"人脸识别详细数据" forState:UIControlStateNormal];
        [_detailDataButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [_detailDataButton addTarget:self action:@selector(getDetailData) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _detailDataButton;
}
- (UILabel *)showPassLab {
    if (!_showPassLab) {
        _showPassLab = [[UILabel alloc]init];
        _showPassLab.font = [UIFont systemFontOfSize:30];
        _showPassLab.textColor = [UIColor redColor];
        _showPassLab.text = @"未通过验证";
        _showPassLab.textAlignment =NSTextAlignmentCenter;
    }
    return _showPassLab;
}
- (UIButton *)showImage {
    if (!_showImage) {
        _showImage = [UIButton buttonWithType:UIButtonTypeCustom];
        [_showImage setTitle:@"上传身份证正面" forState:UIControlStateNormal];
        _showImage.backgroundColor = [UIColor grayColor];
        _showImage.layer.cornerRadius = 12;
        [_showImage setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_showImage addTarget:self action:@selector(checkItImage) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _showImage;
}
- (UIButton *)backShowImage {
    if (!_backShowImage) {
        _backShowImage = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backShowImage setTitle:@"上传身份证背面" forState:UIControlStateNormal];
        _backShowImage.backgroundColor = [UIColor grayColor];
        _backShowImage.layer.cornerRadius = 12;
        [_backShowImage setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return  _backShowImage;
}
- (UIButton *)IdCardInfoButton {
    if (!_IdCardInfoButton) {
        _IdCardInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_IdCardInfoButton setTitle:@"身份证详细信息" forState:UIControlStateNormal];
        [_IdCardInfoButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [_IdCardInfoButton addTarget:self action:@selector(getDetailIdCardInfo) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _IdCardInfoButton;
}
@end
