//
//  ThirdController.m
//  MovePlayer
//
//  Created by apple on 2017/2/21.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ThirdController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>
#import <Photos/Photos.h>

@interface ThirdController ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>{
    CMTime _timeOffset;         //录制的偏移CMTime
    CMTime _lastVideo;          //记录上一次视频数据文件的CMTime
    CMTime _lastAudio;          //记录上一次音频数据文件的CMTime
    
    NSInteger _cx;//视频分辨的宽
    NSInteger _cy;//视频分辨的高
    int _channels;//音频通道
    Float64 _samplerate;//音频采样率
}
@property(nonatomic, assign)BOOL lgtype;                    //闪光灯状态
@property(nonatomic, assign)BOOL type;                      //摄像头状态
@property(nonatomic, strong)UIButton *cutBtn;               //关闭按钮
@property(nonatomic, strong)UIButton *lightBtn;             //闪光的按钮
@property(nonatomic, strong)UIButton *fbBtn;                //改变前后摄像头
@property(nonatomic, strong)UIView *btnView;                //按钮红心
@property(nonatomic, strong)UIButton *videobtn;             //录制按钮
@property(nonatomic, strong)AVCaptureSession *recordSession;//捕获视频的会话
@property(nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property(nonatomic, strong)AVCaptureDeviceInput *backCameraInput;//后置摄像头输入
@property(nonatomic, strong)AVCaptureDeviceInput *frontCameraInput;//前置摄像头输入
@property(nonatomic, copy)dispatch_queue_t           captureQueue;//录制的队列
@property(nonatomic, strong)AVCaptureDeviceInput *audioMicInput;//麦克风输入
@property(nonatomic, strong)AVCaptureConnection *audioConnection;//音频录制连接
@property(nonatomic, strong)AVCaptureConnection *videoConnection;//视频录制连接
@property(nonatomic, strong)AVCaptureVideoDataOutput *videoOutput;//视频输出
@property(nonatomic, strong)AVCaptureAudioDataOutput *audioOutput;//音频输出
@property(nonatomic, assign)CMTime startTime;                     //开始的录制时间
@property(nonatomic, assign)CGFloat currentRecordTime;            //当前录制的时间
@property(nonatomic, copy)NSString *videoPath;         //视频路径
@property(nonatomic, assign)BOOL isCapturing;          //正在录制
@property(nonatomic, assign)BOOL isPaused;             //是否暂停
@property(nonatomic, assign)BOOL discont;              //是否暂停

//数据写入
@property(nonatomic, strong)AVAssetWriter *writer;       //媒体写入对象
@property(nonatomic, strong)AVAssetWriterInput *videoWriter;  //视频写入
@property(nonatomic, strong)AVAssetWriterInput *audioWriter;  //音频写入
@property(nonatomic, copy)NSString *path; //写入路径
@end

@implementation ThirdController

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.recordSession stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.cutBtn];
    [self.view addSubview:self.lightBtn];
    [self.view addSubview:self.fbBtn];
    [self.view addSubview:self.btnView];
    [self.view addSubview:self.videobtn];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    [self.recordSession startRunning];
}

-(UIButton *)cutBtn
{
    if (!_cutBtn) {
        self.cutBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 80, 60)];
        [self.cutBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [self.cutBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cutBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.cutBtn.layer.cornerRadius = 8;
        [self.cutBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cutBtn;
}

-(UIButton *)lightBtn
{
    if (!_lightBtn) {
        self.lightBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-40, 5, 80, 60)];
        [self.lightBtn setTitle:@"开/关" forState:UIControlStateNormal];
        [self.lightBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.lightBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.lightBtn.layer.cornerRadius = 8;
        [self.lightBtn addTarget:self action:@selector(changeFlashState:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _lightBtn;
}

-(UIButton *)fbBtn
{
    if (!_fbBtn) {
        self.fbBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-85, 5, 80, 60)];
        [self.fbBtn setTitle:@"前/后" forState:UIControlStateNormal];
        [self.fbBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.fbBtn setTitleColor:[UIColor purpleColor] forState:UIControlStateHighlighted];
        self.fbBtn.layer.cornerRadius = 8;
        [self.fbBtn addTarget:self action:@selector(fbVideo:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _fbBtn;
}

-(void)close:(UIButton *)sender
{
//    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.videoPath.length > 0) {
       [self stopCaptureHandler:^(UIImage *moveImage) {
           NSLog(@"请查看相册");
       }];
    }
}

-(void)fbVideo:(UIButton *)sender
{
    [self.recordSession stopRunning];
    if (self.type) {
        [self.recordSession removeInput:self.frontCameraInput];
        if ([self.recordSession canAddInput:self.backCameraInput]) {
            //打开闪光灯按钮
            [self.lightBtn setUserInteractionEnabled:YES];
            [self.recordSession addInput:self.backCameraInput];
        }
    }else{
        [self.recordSession removeInput:self.backCameraInput];
        if ([self.recordSession canAddInput:self.frontCameraInput]) {
            //闪光灯不能打开
            [self.lightBtn setUserInteractionEnabled:NO];
            //关闭闪光灯
            [self closeLghtFlash];
            [self.recordSession addInput:self.frontCameraInput];
        }
    }
    self.type = !self.type;
    [self.recordSession startRunning];
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
        if (self.isCapturing) {
            [self resumeCapture];
        }else
            [self starCapture];
    }else
        [self pauseCapture];
}

//开始录制
-(void)starCapture
{
    @synchronized (self) {
        if (!self.isCapturing) {
            _writer = nil;
            _videoWriter = nil;
            _audioWriter = nil;
            self.isPaused = NO;
            self.discont = NO;
            _timeOffset = CMTimeMake(0, 0);
            self.isCapturing = YES;
        }
    }
}

//暂停录制
-(void)pauseCapture
{
    @synchronized (self) {
        if (self.isCapturing) {
            self.isPaused = YES;
            self.discont = YES;
        }
    }
}

//继续录制
-(void)resumeCapture{
    @synchronized (self) {
        if (self.isPaused) {
            self.isPaused = NO;
        }
    }
}

//停止录制
-(void)stopCaptureHandler:(void (^)(UIImage *moveImage))handler{
    @synchronized (self) {
        if (self.isCapturing) {
            NSString *path = self.path;
            NSURL *url = [NSURL URLWithString:path];
            dispatch_async(_captureQueue, ^{
                [self finshWithCompletionHandler:^{
                    self.isCapturing = NO;
                    [_recordSession stopRunning];
                    _captureQueue     = nil;
                    _recordSession    = nil;
                    _previewLayer     = nil;
                    _backCameraInput  = nil;
                    _frontCameraInput = nil;
                    _audioOutput      = nil;
                    _videoOutput      = nil;
                    _audioConnection  = nil;
                    _videoConnection  = nil;
                    _writer = nil;
                    _videoWriter = nil;
                    _audioWriter = nil;
                    _path = nil;
                    self.startTime = CMTimeMake(0, 0);
                    self.currentRecordTime = 0;
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        NSLog(@"保存成功");
                    }];
                }];
            });
        }
    }
}

//获取视频第一帧的图片
- (void)movieToImageHandler:(void (^)(UIImage *movieImage))handler {
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}


//视频录制完成时调用
-(void)finshWithCompletionHandler:(void(^)(void))handler{
    [_writer finishWritingWithCompletionHandler:handler];
}

-(void)changeFlashState:(UIButton *)sender
{
    if (self.lgtype) {
        [self closeLghtFlash];
    }else
        [self openLghtFlash];
    self.lgtype = !self.lgtype;
}

-(void)openLghtFlash
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOff) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOn;
        backCamera.flashMode = AVCaptureFlashModeOn;
        [backCamera unlockForConfiguration];
    }
}

-(void)closeLghtFlash
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOn) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOff;
        backCamera.flashMode = AVCaptureTorchModeOff;
        [backCamera unlockForConfiguration];

    }
}

//捕获视频会话
-(AVCaptureSession *)recordSession
{
    if (_recordSession == nil) {
        _recordSession = [[AVCaptureSession alloc] init];
        //添加后置摄像头的输入
        if ([_recordSession canAddInput:self.backCameraInput]) {
            [_recordSession addInput:self.backCameraInput];
        }
        //添加后置麦克风的输入
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
            //设置视频的分辨率
            _cx = 720;
            _cy = 1280;
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _recordSession;
}

//捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        //通过AVCaptureSession初始化
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
        //设置比例为铺满全屏
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create("cn.qiuyouqun.im.wclrecordengine.capture", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}


//视频输出
-(AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary *setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

//通过这个方法写入数据
- (BOOL)encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo {
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态为未知,保证视频先写入
        if (_writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (_writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        //判断是否是视频
        if (isVideo) {
            //视频输入是否准备接受更多的媒体数据
            if (_videoWriter.readyForMoreMediaData == YES) {
                //拼接数据
                [_videoWriter appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }else {
            //音频输入是否准备接受更多的媒体数据
            if (_audioWriter.readyForMoreMediaData) {
                //拼接数据
                [_audioWriter appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }
    }
    return NO;
}

//麦克风输入
-(AVCaptureDeviceInput *)audioMicInput
{
    if (!_audioMicInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败");
        }
    }
    return _audioMicInput;
}

//取得后置摄像头
-(AVCaptureDeviceInput *)backCameraInput
{
    if (!_backCameraInput) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获得后置摄像头失败");
        }
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}

//返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark - 写入数据
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    BOOL isVideo = YES;
    @synchronized (self) {
        if (!self.isCapturing || self.isPaused) {
            return;
        }
        
        if (captureOutput != self.videoOutput) {
            isVideo = NO;
        }
        
        //初始化编码器,当有音频和视频参数时创建编码器
        if ([self isNill] && !isVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            NSString *videoName = [self getUploadFile_type:@"video" fileType:@"mp4"];
            self.videoPath = [[self getVideoCachePath] stringByAppendingString:videoName];
            [self insPath:self.videoPath Height:_cy width:_cx channels:_channels samples:_samplerate];
        }
        
        //判断是否中断录制过
        if (self.discont) {
            if (isVideo) {
                return;
            }
            self.discont = NO;
            //计算暂停时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = isVideo ? _lastVideo:_lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }else{
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
                _lastVideo.flags = 0;
                _lastAudio.flags = 0;
            }
        }
        //增加sampleBuffer的引用计时,这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
        }
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (isVideo) {
            _lastVideo = pts;
        }else {
            _lastAudio = pts;
        }
    }
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = dur;
    }
    CMTime sub = CMTimeSubtract(dur, self.startTime);
    self.currentRecordTime = CMTimeGetSeconds(sub);
    // 进行数据编码
    [self encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);
}


//初始化方法
- (void)insPath:(NSString*)path Height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samples:(Float64) rate {
        self.path = path;
        //先把路径下的文件给删除掉，保证录制的文件是最新的
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        NSURL* url = [NSURL fileURLWithPath:self.path];
        //初始化写入媒体类型为MP4类型
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        //使其更适合在网络上播放
        _writer.shouldOptimizeForNetworkUse = YES;
        //初始化视频输出
        [self initVideoInputHeight:cy width:cx];
        //确保采集到rate和ch
        if (rate != 0 && ch != 0) {
            //初始化音频输出
            [self initAudioInputChannels:ch samples:rate];
        }
}

//初始化视频输入
- (void)initVideoInputHeight:(NSInteger)cy width:(NSInteger)cx {
    //录制视频的一些配置，分辨率，编码方式等等
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              [NSNumber numberWithInteger: cx], AVVideoWidthKey,
                              [NSNumber numberWithInteger: cy], AVVideoHeightKey,
                              nil];
    //初始化视频写入类
    _videoWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoWriter.expectsMediaDataInRealTime = YES;
    //将视频输入源加入
    [_writer addInput:_videoWriter];
}

//初始化音频输入
- (void)initAudioInputChannels:(int)ch samples:(Float64)rate {
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [ NSNumber numberWithInt: ch], AVNumberOfChannelsKey,
                              [ NSNumber numberWithFloat: rate], AVSampleRateKey,
                              [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
                              nil];
    //初始化音频写入类
    _audioWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _audioWriter.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    [_writer addInput:_audioWriter];
    
}

//获得视频存放地址
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ) {
        //如果文件不存在，创建文件
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}

- (NSString *)getUploadFile_type:(NSString *)type fileType:(NSString *)fileType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@",type,timeStr,fileType];
    return fileName;
}

//设置音频格式
- (void)setAudioFormat:(CMFormatDescriptionRef)fmt {
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
    
}


-(BOOL)isNill
{
    if (!self.writer && !self.videoWriter && !self.audioWriter &&!self.path) {
        return YES;
    }
    return NO;
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
