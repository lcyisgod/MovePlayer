//
//  VideoTranscribe.h
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//

/*
 **本类为视屏录制类，用于显示视频情况，不进行具体的视频录入
 **该类功能包括视频开始，录制，暂停，结束；闪光灯等操作方法
 */
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//计算当前的录制进度
@protocol getRate <NSObject>
@optional
-(void)recodeProgress:(CGFloat)progress;
//视频文件是否存储成功
-(void)saveSuccess;
-(void)saveDefaultWithError:(NSError *)erroy;
@end
@interface VideoTranscribe : NSObject
@property (nonatomic, assign)id<getRate>delegate;
@property (nonatomic, strong) NSString *videoPath;
//获取视频展示界面
-(AVCaptureVideoPreviewLayer *)previewLayer;
//启动录制功能
-(void)startUp;
//关闭录制功能
-(void)shutDown;
//开始录制
-(void)startCapture;
//暂停录制
-(void)pasueCapture;
//停止录制
-(void)stopCaptureHandler:(void (^)(UIImage *moveImg))handle;
//继续录制
-(void)resumeCapture;

//打开闪光灯
-(void)openFlash;
//关闭闪光灯
-(void)closeFlash;
//开启前置摄像头
-(void)openfrontCamera;
//开启后置摄像头
-(void)openBackCamera;

//获取播放状态
-(BOOL)getCapturing;
//设置最长播放时间
-(void)setMaxRecordTimes:(CGFloat)maxRecordTime;
@end
