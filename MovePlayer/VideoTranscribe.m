//
//  VideoTranscribe.m
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "VideoTranscribe.h"
#import "VideoWriter.h"
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>
#import <Photos/Photos.h>

static VideoTranscribe *videoTranscribe = nil;

@interface VideoTranscribe ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>{
    CMTime _timeOffset;       //录制的时间偏移
    CMTime _lastVideo;        //记录上次视频数据文件的CMTime
    CMTime _lastAudio;        //记录上次音频数据文件的CMtime
    
    NSInteger _cx;            //宽
    NSInteger _cy;            //高
    int _channels;            //视频采样率
    Float64 _samplerate;      //音频采样率
}
@property(nonatomic, strong)VideoWriter *videoWriter;                   //录制对象
@property(nonatomic, strong)AVCaptureSession *recodeSession;            //视频录入会话
@property(nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;   //视频录入显示层
@property(nonatomic, strong)AVCaptureDeviceInput *backCameraInput;      //后置摄像头输入
@property(nonatomic, strong)AVCaptureDeviceInput *frontCameraInput;     //前置摄像头输入
@property(nonatomic, strong)AVCaptureDeviceInput *audionInput;          //麦克风输入
@property(nonatomic, strong)AVCaptureConnection  *videoConnection;      //视频连接
@property(nonatomic, strong)AVCaptureConnection  *audioConnection;      //音频链接
@property(nonatomic, copy)dispatch_queue_t captureQuece;                //录制的队列
@property(nonatomic, strong)AVCaptureVideoDataOutput *videoDataOutPut;  //视频数据输出
@property(nonatomic, strong)AVCaptureAudioDataOutput *audioDataOutPut;  //音频数据输出
@property(nonatomic, assign)BOOL isCapturing;                           //正在录制
@property(nonatomic, assign)BOOL isPasued;                              //是否暂停
@property(nonatomic, assign)BOOL discount;                              //是否中断
@property(nonatomic, assign)CMTime startTime;                           //开始录制时间
@property(nonatomic, assign)CGFloat currentRecordTime;                  //当前录制时间
@property (nonatomic, assign) CGFloat maxRecordTime;//录制最长时间
@end
@implementation VideoTranscribe


+(VideoTranscribe *)shareDefault
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        videoTranscribe = [[VideoTranscribe alloc] init];
    });
    return videoTranscribe;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        //默认最长录制时间一分钟
        self.maxRecordTime = 60.0;
    }
    return self;
}

//创建视频会话
-(AVCaptureSession *)recodeSession
{
    if (!_recodeSession) {
        self.recodeSession = [[AVCaptureSession alloc] init];
        //添加后置摄像头
        if ([self.recodeSession canAddInput:self.backCameraInput]) {
            [self.recodeSession addInput:self.backCameraInput];
        }
        
        //添加麦克风
        if ([self.recodeSession canAddInput:self.audionInput]) {
            [self.recodeSession addInput:self.audionInput];
        }
        
        //添加视频输出
        if ([self.recodeSession canAddOutput:self.videoDataOutPut]) {
            [self.recodeSession addOutput:self.videoDataOutPut];
            //视频分辨率
            _cx = 720;
            _cy = 1280;
        }
        //添加音频输出
        if ([self.recodeSession canAddOutput:self.audioDataOutPut]) {
            [self.recodeSession addOutput:self.audioDataOutPut];
        }
        //设置视频录制方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _recodeSession;
}
//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioDataOutPut connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}


//获取后置摄像头
-(AVCaptureDeviceInput *)backCameraInput
{
    if (!_backCameraInput) {
        NSError *error;
        self.backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamer] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败");
        };
    }
    return _backCameraInput;
}

//返回后置摄像头
-(AVCaptureDevice *)backCamer
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}


//获取前置摄像头
-(AVCaptureDeviceInput *)frontCameraInput
{
    if (!_frontCameraInput) {
        NSError *error;
        self.frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败");
        }
    }
    return _frontCameraInput;
}

//获取麦克风设备
-(AVCaptureDeviceInput *)audionInput
{
    if (!_audionInput) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        self.audionInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        if (error) {
            NSLog(@"获取麦克风失败");
        }
    }
    return _audionInput;
}

//返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回摄像头类型
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

//视频输出
-(AVCaptureVideoDataOutput *)videoDataOutPut
{
    if (!_videoDataOutPut) {
        self.videoDataOutPut = [[AVCaptureVideoDataOutput alloc] init];
        [self.videoDataOutPut setSampleBufferDelegate:self queue:self.captureQuece];
        //设置视频参数
        NSDictionary *sercapSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],kCVPixelBufferPixelFormatTypeKey, nil];
        self.videoDataOutPut.videoSettings = sercapSettings;
    }
    return _videoDataOutPut;
}



//音频输出
-(AVCaptureAudioDataOutput *)audioDataOutPut
{
    if (!_audioDataOutPut) {
        self.audioDataOutPut = [[AVCaptureAudioDataOutput alloc] init];
        [self.audioDataOutPut setSampleBufferDelegate:self queue:self.captureQuece];
    }
    return _audioDataOutPut;
}

//录制的队列
-(dispatch_queue_t)captureQuece
{
    if (_captureQuece == nil) {
        _captureQuece = dispatch_queue_create("cn.lcy", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQuece;
}

#pragma mark-Layer
-(AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        //通过AVCaptureSession初始化
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recodeSession];
        //设置为铺满全屏
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

#pragma mark - 设备操作方法
-(void)startUp
{
    self.startTime = CMTimeMake(0, 0);
    [self.recodeSession startRunning];
}

-(void)shutDown
{
    self.startTime = CMTimeMake(0, 0);
    [self.recodeSession stopRunning];
    [self.videoWriter finishWithCompletionHandler:^{
        
    }];
}

-(void)startCapture
{
    @synchronized (self) {
        if (!self.isCapturing) {
            self.videoWriter = nil;
            self.isCapturing = YES;
            self.isPasued = NO;
            self.discount = NO;
            _timeOffset = CMTimeMake(0, 0);
        }
    }
}

-(void)pasueCapture
{
    @synchronized (self) {
        if (self.isCapturing) {
            self.isPasued = YES;
            self.discount = YES;
        }
    }
}

-(void)stopCaptureHandler:(void (^)(UIImage *))handle
{
    @synchronized (self) {
        if (self.isCapturing) {
            NSString *path = self.videoWriter.path;
            NSURL *url = [NSURL URLWithString:path];
            self.isCapturing = NO;
            dispatch_async(_captureQuece, ^{
               [self.videoWriter finishWithCompletionHandler:^{
                   self.videoWriter = nil;
                   self.startTime = CMTimeMake(0, 0);
                   self.currentRecordTime = 0;
                   [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                       [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                   } completionHandler:^(BOOL success, NSError * _Nullable error) {
                       if (!error) {
                           if ([self.delegate respondsToSelector:@selector(saveSuccess)]) {
                               [self.delegate saveSuccess];
                           }
                       }else{
                           if ([self.delegate respondsToSelector:@selector(saveDefaultWithError:)]) {
                               [self.delegate saveDefaultWithError:error];
                           }
                       }
                   }];
                   [self movieToImageHandler:handle];
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

-(void)resumeCapture
{
    @synchronized (self) {
        if (self.isPasued) {
            self.isPasued = NO;
        }
    }
}

-(void)openFlash
{
    AVCaptureDevice *device = [self backCamer];
    if (device.torchMode == AVCaptureTorchModeOff) {
        [device lockForConfiguration:nil];
        device.torchMode = AVCaptureTorchModeOn;
        device.flashMode = AVCaptureFlashModeOn;
        [device unlockForConfiguration];
    }
}

-(void)closeFlash
{
    AVCaptureDevice *device = [self backCamer];
    if (device.torchMode == AVCaptureTorchModeOn) {
        [device lockForConfiguration:nil];
        device.torchMode = AVCaptureTorchModeOff;
        device.flashMode = AVCaptureFlashModeOff;
        [device unlockForConfiguration];
    }

}

-(void)changeVideoWithType:(BOOL)type
{
    [self.recodeSession stopRunning];
    if (type) {
        [self.recodeSession removeInput:self.frontCameraInput];
        if ([self.recodeSession canAddInput:self.backCameraInput]) {
            [self.recodeSession addInput:self.backCameraInput];
        }
    }else{
        [self.recodeSession removeInput:self.backCameraInput];
        if ([self.recodeSession canAddInput:self.frontCameraInput]) {
            [self.recodeSession addInput:self.frontCameraInput];
            //关闭闪光灯
            [self closeFlash];
        }
    }
    [self.recodeSession startRunning];
}

-(BOOL)getCapturing
{
    return self.isCapturing;
}

-(void)setMaxRecordTimes:(CGFloat)maxRecordTime
{
    self.maxRecordTime = maxRecordTime;
}

#pragma mark - 代理方法
//写入数据
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //是否在录制
    BOOL isVideo = YES;
    @synchronized (self) {
        //没有录制或者暂停的时候不写入数据
        if (!self.isCapturing || self.isPasued) {
            return;
        }
        
        if (captureOutput != self.videoDataOutPut) {
            isVideo = NO;
        }
        //初始化编码器，当有音频线和视频参数时创建编码器
        if ((self.videoWriter == nil) && !isVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            NSString *videoName = [self getUploadFile_type:@"video" fileType:@"mp4"];
            self.videoPath = [[self getVideoCachePath] stringByAppendingPathComponent:videoName];
            self.videoWriter = [VideoWriter encoderWithPath:self.videoPath Height:_cy Width:_cx channels:_channels samples:_samplerate];
            
        }
        //是否中断录制过
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.discount) {
            if (isVideo) {
                return;
            }
            self.discount = NO;
            //计算暂停时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = isVideo? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, last);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }else
                    _timeOffset = CMTimeSubtract(_timeOffset, offset);
            }
            _lastAudio.flags = 0;
            _lastVideo.flags = 0;
        }
        //增加sampleBuffer的引用计数,这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
        // 记录暂停上一次录制的时间
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
    if (_timeOffset.value == 0) {
        self.currentRecordTime = CMTimeGetSeconds(sub);
    }else{
        CMTime sub1 = CMTimeSubtract(sub, _timeOffset);
        self.currentRecordTime = CMTimeGetSeconds(sub1);
    }
    if (self.currentRecordTime > self.maxRecordTime) {
        if (self.currentRecordTime - self.maxRecordTime < 0.1) {
            if ([self.delegate respondsToSelector:@selector(recodeProgress:)]) {
                [self.delegate recodeProgress:self.currentRecordTime/self.maxRecordTime];
            }
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(recodeProgress:)]) {
        [self.delegate recodeProgress:self.currentRecordTime/self.maxRecordTime];
    }
    // 进行数据编码
    [self.videoWriter encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);

}

//设置音频格式
- (void)setAudioFormat:(CMFormatDescriptionRef)fmt {
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
    
}
//创建音频文件路径
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

//获得视频存放地址
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}




@end
