//
//  IDInfoViewControllers.m
//  TestFramework
//
//  Created by yhb on 2020/11/24.
//  Copyright © 2020 seetadev. All rights reserved.
//

#import "IDInfoViewControllers.h"
#import "Masonry.h"
#import "IDInfo.h"
@interface IDInfoViewControllers()
@property (strong, nonatomic)  UIImageView *IDImageView;
@property (strong, nonatomic)  UILabel *IDNumLabel;
@property (strong, nonatomic)  UILabel *nameLabel;
@property (strong, nonatomic)  UILabel *sexLabel;
@property (strong, nonatomic)  UILabel *nationLabel;
@property (strong, nonatomic)  UILabel *adressLabel;
@property (strong, nonatomic)  UILabel *VisaAgencyLabel;
@property (strong, nonatomic)  UILabel *TermOfValidityLabel;
@property (nonatomic,strong) UIButton *leftButton;
@property (nonatomic,strong) UIButton *rightButton;
@end
@implementation IDInfoViewControllers
- (instancetype)initWithModel:(IDInfo *)info image:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.IDInfo = info;
        self.IDImage = image;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"身份证信息";
    self.view.backgroundColor = [UIColor whiteColor];
    [self add_setUpUI];
    [self add_setData];
}
- (void)add_setData {
    NSString *IDInfoStr = [NSString stringWithFormat:@"身份证号码:%@",self.IDInfo.num];
    self.IDNumLabel.text =  IDInfoStr;
    NSString *nameStr = [NSString stringWithFormat:@"姓名:%@",self.IDInfo.name];

    self.nameLabel.text = nameStr;
    NSString *sexStr = [NSString stringWithFormat:@"性别:%@",self.IDInfo.gender];
    self.sexLabel.text = sexStr;
    NSString *nationStr = [NSString stringWithFormat:@"国家:%@",self.IDInfo.nation];
    self.nationLabel.text = nationStr;
    NSString *adresStr = [NSString stringWithFormat:@"地址:%@",self.IDInfo.address];
    self.adressLabel.text = adresStr;
}
- (void)add_setUpUI {
    [self.view addSubview:self.IDImageView];
    [self.view addSubview:self.IDNumLabel];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.sexLabel];
    [self.view addSubview:self.nationLabel];
    [self.view addSubview:self.adressLabel];
    [self.view addSubview:self.leftButton];
    [self.view addSubview:self.rightButton];
    [self add_masonry];
}
- (void)add_masonry {
    [self.IDImageView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.mas_offset(100);
        make.height.mas_equalTo(180);
    }];
    [self.IDNumLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.IDImageView.mas_bottom).offset(15);
        make.height.mas_equalTo(20);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.IDNumLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(20);
    }];
    [self.sexLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(20);
    }];
    [self.nationLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
        make.top.equalTo(self.sexLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(20);
    }];

    [self.adressLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_offset(12);
        make.right.mas_offset(-12);
//        make.height.mas_equalTo(60);
        make.top.equalTo(self.nationLabel.mas_bottom).offset(15);
    }];
    [self.leftButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.bottom.mas_offset(-30);
        make.left.mas_offset(12);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(50);
    }];
    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make){
        make.bottom.mas_offset(-30);
        make.right.mas_offset(-12);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(50);
    }];
}
//MARK: 描述 - event
- (void)checkLeftButton {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)checkRightButton {
    NSLog(@"经用户核对，身份证号码正确，那就进行下一步，比如身份证图像或号码经加密后，传递给后台");
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)setIDImage:(UIImage *)IDImage {
    [self.IDImageView setImage:IDImage];
}
- (UIImageView *)IDImageView {
    if (!_IDImageView) {
        _IDImageView = [[UIImageView alloc]init];
        _IDImageView.contentMode = UIViewContentModeScaleAspectFill;
        _IDImageView.layer.cornerRadius = 8;
        _IDImageView.layer.masksToBounds = YES;
    }
    return _IDImageView;
}
- (UILabel *)IDNumLabel {
    if (!_IDNumLabel) {
        _IDNumLabel = [[UILabel alloc]init];
        _IDNumLabel.font =[UIFont systemFontOfSize:20];
        _IDNumLabel.numberOfLines = 0;
        _IDNumLabel.textColor = [UIColor blackColor];
    }
    return _IDNumLabel;
}
- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font =[UIFont systemFontOfSize:20];
        _nameLabel.numberOfLines = 0;
        _nameLabel.textColor = [UIColor blackColor];
    }
    return _nameLabel;
}

- (UILabel *)sexLabel {
    if (!_sexLabel) {
        _sexLabel = [[UILabel alloc]init];
        _sexLabel.font =[UIFont systemFontOfSize:20];
        _sexLabel.numberOfLines = 0;
        _sexLabel.textColor = [UIColor blackColor];
    }
    return _sexLabel;
}
- (UILabel *)nationLabel {
    if (!_nationLabel) {
        _nationLabel = [[UILabel alloc]init];
        _nationLabel.font =[UIFont systemFontOfSize:20];
        _nationLabel.numberOfLines = 0;
        _nationLabel.textColor = [UIColor blackColor];
    }
    return _nationLabel;
}
- (UILabel *)adressLabel {
    if (!_adressLabel) {
        _adressLabel = [[UILabel alloc]init];
        _adressLabel.font =[UIFont systemFontOfSize:20];
        _adressLabel.numberOfLines = 0;
        _adressLabel.textColor = [UIColor blackColor];
    }
    return _adressLabel;
}
- (UILabel *)VisaAgencyLabel {
    if (!_VisaAgencyLabel) {
        _VisaAgencyLabel = [[UILabel alloc]init];
        _VisaAgencyLabel.font =[UIFont systemFontOfSize:20];
        _VisaAgencyLabel.numberOfLines = 0;
        _VisaAgencyLabel.textColor = [UIColor blackColor];
    }
    return _VisaAgencyLabel;
}
- (UILabel *)TermOfValidityLabel {
    if (!_TermOfValidityLabel) {
        _TermOfValidityLabel = [[UILabel alloc]init];
        _TermOfValidityLabel.font =[UIFont systemFontOfSize:20];
        _TermOfValidityLabel.numberOfLines = 0;
        _TermOfValidityLabel.textColor = [UIColor blackColor];
        
    }
    return _TermOfValidityLabel;
}
- (UIButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _leftButton.backgroundColor = [UIColor orangeColor];
        [_leftButton setTitle:@"错误重新拍" forState:UIControlStateNormal];
        [_leftButton addTarget:self action:@selector(checkLeftButton) forControlEvents:UIControlEventTouchUpInside];

    }
    return _leftButton;
}
- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _rightButton.backgroundColor = [UIColor orangeColor];
        [_rightButton setTitle:@"正确下一步" forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(checkRightButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightButton;
}
@end
