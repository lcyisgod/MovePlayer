//
//  FourController.m
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "FourController.h"
#import "VideoTranscribe.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>


@interface FourController ()<getRate>
@property(nonatomic, assign)BOOL lgtype;                    //闪光灯状态
@property(nonatomic, assign)BOOL type;                      //摄像头状态
@property(nonatomic, strong)UIButton *cutBtn;               //关闭按钮
@property(nonatomic, strong)UIButton *lightBtn;             //闪光的按钮
@property(nonatomic, strong)UIButton *fbBtn;                //改变前后摄像头
@property(nonatomic, strong)UIButton *stopBtn;              //结束录制
@property(nonatomic, strong)UIView *btnView;                //按钮红心
@property(nonatomic, strong)UIButton *videobtn;             //录制按钮
@property(nonatomic, strong)VideoTranscribe *videoTrans;    //视频录制对象
@property(nonatomic, strong)UIProgressView *progressView;
@end

@implementation FourController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.videoTrans = [VideoTranscribe shareDefault];
    self.videoTrans.delegate = self;
    [self.videoTrans previewLayer].frame = self.view.bounds;
    [self.view.layer insertSublayer:[self.videoTrans previewLayer] atIndex:0];
    [self.videoTrans startUp];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.videoTrans shutDown];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.cutBtn];
    [self.view addSubview:self.lightBtn];
    [self.view addSubview:self.fbBtn];
    [self.view addSubview:self.stopBtn];
    [self.view addSubview:self.btnView];
    [self.view addSubview:self.videobtn];
    [self.view addSubview:self.progressView];
}

-(UIButton *)cutBtn
{
    if (!_cutBtn) {
        self.cutBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 80, 60)];
        [self.cutBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [self.cutBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cutBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.cutBtn.layer.cornerRadius = 8;
        [self.cutBtn addTarget:self action:@selector(close1:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cutBtn;
}

-(UIButton *)lightBtn
{
    if (!_lightBtn) {
        self.lightBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-90, 5, 80, 60)];
        [self.lightBtn setTitle:@"开/关" forState:UIControlStateNormal];
        [self.lightBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.lightBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.lightBtn.layer.cornerRadius = 8;
        [self.lightBtn addTarget:self action:@selector(changeFlashState1:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _lightBtn;
}

-(UIButton *)fbBtn
{
    if (!_fbBtn) {
        self.fbBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x + 10, 5, 80, 60)];
        [self.fbBtn setTitle:@"前/后" forState:UIControlStateNormal];
        [self.fbBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.fbBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.fbBtn.layer.cornerRadius = 8;
        [self.fbBtn addTarget:self action:@selector(fbVideo1:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fbBtn;
}

-(UIButton *)stopBtn
{
    if (!_stopBtn) {
        self.stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-85, 5, 80, 60)];
        [self.stopBtn setTitle:@"完成" forState:UIControlStateNormal];
        [self.stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.stopBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.stopBtn.layer.cornerRadius = 8;
        [self.stopBtn addTarget:self action:@selector(stopVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}


-(void)close1:(UIButton *)sender
{
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)fbVideo1:(UIButton *)sender
{
    //闪光灯按钮状态
    [self.lightBtn setUserInteractionEnabled:self.type];
    [self.videoTrans changeVideoWithType:self.type];
    self.type = !self.type;
}

-(void)changeFlashState1:(UIButton *)sender
{
    if (self.lgtype) {
        [self.videoTrans closeFlash];
    }else
        [self.videoTrans openFlash];
    self.lgtype = !self.lgtype;
}

-(void)stopVideo:(UIButton *)sender
{
    if (self.videoTrans.videoPath.length > 0) {
        [self.videoTrans stopCaptureHandler:^(UIImage *movieImage) {
           
        }];
    }else{
        NSLog(@"先录制视频");
    }
}

-(UIButton *)videobtn
{
    if (!_videobtn) {
        self.videobtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-30, self.view.frame.size.height-70, 60, 60)];
        self.videobtn.layer.borderWidth = 3;
        self.videobtn.layer.borderColor = [UIColor blueColor].CGColor;
        [self.videobtn setBackgroundColor:[UIColor clearColor]];
        self.videobtn.layer.cornerRadius = 30;
        [self.videobtn addTarget:self action:@selector(videoStart:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videobtn;
}

-(UIProgressView *)progressView
{
    if (!_progressView) {
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(self.videobtn.frame)-5, self.view.frame.size.width, 2)];
        self.progressView.progressTintColor = [UIColor blueColor];
        self.progressView.tintColor = [UIColor redColor];
    }
    return _progressView;
}


-(UIView *)btnView
{
    if (!_btnView) {
        self.btnView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x-20, self.view.frame.size.height-60, 40, 40)];
        self.btnView.layer.cornerRadius = 20;
        self.btnView.backgroundColor = [UIColor redColor];
    }
    return _btnView;
}

-(void)videoStart:(UIButton *)sender
{
    self.videobtn.selected = !self.videobtn.selected;
    if (self.videobtn.selected) {
        if ([self.videoTrans getCapturing]) {
            [self.videoTrans resumeCapture];
        }else
            [self.videoTrans startCapture];
    }else
        [self.videoTrans pasueCapture];
}

#pragma delegate
-(void)recodeProgress:(CGFloat)progress
{
    NSLog(@"%.2f",progress);
}

-(void)saveSuccess
{
    if ([self.delegate respondsToSelector:@selector(getVideoPath:)]) {
        [self.delegate getVideoPath:self.videoTrans.videoPath];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)saveDefaultWithError:(NSError *)erroy
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
