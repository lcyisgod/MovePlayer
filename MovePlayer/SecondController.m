//
//  SecondController.m
//  MovePlayer
//
//  Created by apple on 2017/2/17.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "SecondController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ThirdController.h"
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface SecondController ()<AVCaptureFileOutputRecordingDelegate>   //视频文件输出处理
@property(nonatomic, strong)AVCaptureSession *captureSession;           //负责输入和输出设备之间的数据传递
@property(nonatomic, strong)AVCaptureDeviceInput *captureDeviceInput;   //负责从Device获得输入数据
@property(nonatomic, strong)AVCaptureMovieFileOutput *captureMoveOut;   //视频输出流
@property(nonatomic, strong)AVCaptureVideoPreviewLayer *capturePrelayer;//相机拍摄预览
@property(nonatomic, assign)BOOL enableRotaion;                         //是否允许旋转
@property(nonatomic, assign)CGRect *lastBounds;                         //旋转前的大小
@property(nonatomic, assign)UIBackgroundTaskIdentifier *taskIdentifier; //后台任务标示
@property(nonatomic, strong)UIView *viewContainer;
@property(nonatomic, strong)UIButton *takeBtn;                          //拍照按钮
@property(nonatomic, strong)UIButton *focus;                            //聚焦光标
@end

@implementation SecondController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pushNext:)]];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.takeBtn];
    [self.view addSubview:self.viewContainer];
    [self setUp];
}

-(void)pushNext:(UIBarButtonItem *)sender
{
    ThirdController *secVC = [ThirdController new];
    [self presentViewController:secVC animated:YES completion:nil];

}

-(UIButton *)takeBtn
{
    if (!_takeBtn) {
        self.takeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-40, self.view.frame.size.height-134, 80, 60)];
        [self.takeBtn setTitle:@"录制" forState:UIControlStateNormal];
        [self.takeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.takeBtn addTarget:self action:@selector(startRunning:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _takeBtn;
}

-(UIView *)viewContainer
{
    if (!_viewContainer) {
        self.viewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 300)];
        self.viewContainer.backgroundColor = [UIColor redColor];
    }
    return _viewContainer;
}

-(void)startRunning:(UIButton *)sender
{
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMoveOut connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (![self.captureMoveOut isRecording]) {

        //如果支持多任务则则开始多任务
//        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
//            self.taskIdentifier=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
//        }
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.capturePrelayer connection].videoOrientation;
        NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
        NSLog(@"save path is :%@",outputFielPath);
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        [self.captureMoveOut startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else{
        [self.captureMoveOut stopRecording];//停止录制
    }
}


-(void)setUp
{
    //初始化会话
    _captureSession = [AVCaptureSession new];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置视频分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    //获得输入设备
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题");
        return;
    }
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    //输入设备初始化输入对象，用于获得输入数据
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错1,错误原因%@",error.localizedDescription);
        return;
    }
    
    AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错2,错误原因%@",error.localizedDescription);
        return;
    }
    //初始化设备输出对象，用于获得输出数据
    _captureMoveOut = [AVCaptureMovieFileOutput new];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection = [_captureMoveOut connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMoveOut]) {
        [_captureSession addOutput:_captureMoveOut];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _capturePrelayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    CALayer *layer = self.viewContainer.layer;
    layer.masksToBounds = YES;
    
    _capturePrelayer.frame = layer.bounds;
    _capturePrelayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //将视频预览层添加到界面中
//    [layer addSublayer:_capturePrelayer];
    [self.viewContainer.layer insertSublayer:_capturePrelayer atIndex:0];
    _enableRotaion = YES;
    
    [self addNotificationToCaptureDevice:captureDevice];
}

#pragma mark - 通知
/**
 *  给输入设备添加通知
 */
-(void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

-(void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}

-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
/**
 *  移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

-(void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"会话发生错误.");
}

-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.");
    //视频录入完成之后在后台将视频存储到相簿
    ALAssetsLibrary *assetsLibrary=[[ALAssetsLibrary alloc]init];
    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
        }
        NSLog(@"成功保存视频到相簿.");
    }];
    
}


#pragma mark - 私有方法
//获取摄像头
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
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
