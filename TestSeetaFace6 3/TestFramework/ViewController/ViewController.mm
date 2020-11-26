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
#import "UIAlertController+Extend.h"
#import "AVCaptureViewController.h"
#import "JQAVCaptureViewController.h"
#import "IDInfoViewControllers.h"
#import "IDInfo.h"
//#import <string.h>
#import <string.h>
#import "testImageViewController.h"
#include <stdlib.h>
#define EHiWeakSelf(type)           __weak typeof(type) weak##type = type;
#define EHiStrongSelf(_instance)    __strong typeof(weak##_instance) _instance = weak##_instance;


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

@property (nonatomic,strong) UIImage *backIdCardImg;
@property (nonatomic,strong) SeetaImageModel *model;
//数据
//------------------  数据  ---------------------
//后台传入的图片数据
@property (nonatomic,strong) NSArray<UIImage *> *imageArry;

@property (nonatomic,strong) OpencvCameraViewController *vc;

@property (nonatomic,strong) IDInfo *info;

@property (nonatomic,strong) UIButton *imageTestButton;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"身份证验证Demo";
    [self p_setUpUI];
}
//MARK: 描述 -delegate

- (void)pickerFormLibray {
    AVCaptureViewController *AVCaptureVC = [[AVCaptureViewController alloc] init];
    EHiWeakSelf(self)
        AVCaptureVC.SelectedCallBack = ^(UIImage *img) {
            EHiStrongSelf(self)

            [self.showImage setImage:img forState:UIControlStateNormal];
            self.IdcardImage = img;
        };
    AVCaptureVC.SelectedIdCardInfoCallBack = ^(IDInfo *info) {
        EHiStrongSelf(self)
        self.info = info;
    };
    [self.navigationController pushViewController:AVCaptureVC animated:YES];
}
- (void)pickerFormBackLibray {
    JQAVCaptureViewController *JQAVCaptureVC = [[JQAVCaptureViewController alloc] init];
    EHiWeakSelf(self)
    JQAVCaptureVC.SelectedCallBack = ^(UIImage *img) {
            EHiStrongSelf(self)

            [self.backShowImage setImage:img forState:UIControlStateNormal];
            self.backIdCardImg = img;
        };
    
    [self.navigationController pushViewController:JQAVCaptureVC animated:YES];
}
- (void)selectedImage:(UIImage *)photos {
    [self.showImage setImage:photos forState:UIControlStateNormal];
    self.IdcardImage = photos;
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
                    [[UIScreen mainScreen]setBrightness:self.vc.currentLight];
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


- (void)p_setUpUI {
    [self.view addSubview:self.uploadImageButton];
    [self.view addSubview:self.detailDataButton];
    [self.view addSubview:self.showPassLab];
    [self.view addSubview:self.showImage];
    [self.view addSubview:self.backShowImage];
    [self.view addSubview:self.IdCardInfoButton];
    [self.view addSubview:self.imageTestButton];
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
        make.height.mas_equalTo(180);
    }];
    [self.backShowImage mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.showImage.mas_bottom).offset(12);
        make.height.mas_equalTo(180);
    }];
    [self.imageTestButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.height.mas_equalTo(30);
        make.bottom.equalTo(self.detailDataButton.mas_top).offset(-18);
    }];

}
//MARK: 描述 - event
- (void)getDetailData {
    
}

- (void)didClickIt {
    if (self.IdcardImage && self.backIdCardImg) {
        self.vc.IdCardImg = self.IdcardImage;
        [self.navigationController pushViewController:self.vc animated:NO];
    } else {
        EHiWeakSelf(self)
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EHiStrongSelf(self)
            [self.navigationController popViewControllerAnimated:YES];
        }];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"未检测到身份证信息" okAction:okAction cancelAction:nil];
        [self.navigationController presentViewController:alertController animated:false completion:nil];
    }
}

- (void)getDetailIdCardInfo {
    if (self.info) {
        IDInfoViewControllers *infoVC = [[IDInfoViewControllers alloc]init];
        infoVC.IDInfo = self.info;
        infoVC.IDImage = self.IdcardImage;
        [self.navigationController pushViewController:infoVC animated:NO];
    }else {
        EHiWeakSelf(self)
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EHiStrongSelf(self)
            [self.navigationController popViewControllerAnimated:YES];
        }];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"未检测到身份证信息" okAction:okAction cancelAction:nil];
        [self.navigationController presentViewController:alertController animated:false completion:nil];
    }

}
- (void)testImage {
    testImageViewController *vc = [[testImageViewController alloc]init];
    [self.navigationController pushViewController:vc animated:NO];
}
- (void)checkItBackImage {
    [self pickerFormBackLibray];

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
//        [_detailDataButton setTitle:@"人脸识别详细数据" forState:UIControlStateNormal];
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
        [_backShowImage addTarget:self action:@selector(checkItBackImage) forControlEvents:UIControlEventTouchUpInside];
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

- (UIButton *)imageTestButton {
    if (!_imageTestButton) {
        _imageTestButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageTestButton setTitle:@"测试数据" forState:UIControlStateNormal];
        _imageTestButton.backgroundColor = [UIColor orangeColor];
        [_imageTestButton addTarget:self action:@selector(testImage) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _imageTestButton;
}
@end
