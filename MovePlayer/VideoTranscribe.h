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

-(void)recodeProgress:(CGFloat)progress;

@end
@interface VideoTranscribe : NSObject
@property (nonatomic, assign)id<getRate>delegate;
@property (nonatomic, assign, readonly) BOOL isCapturing;//正在录制
@property (nonatomic, assign, readonly) BOOL isPaused;//是否暂停
@property (nonatomic, assign, readonly) CGFloat currentRecordTime;//当前录制时间
@property (nonatomic, assign) CGFloat maxRecordTime;//录制最长时间
@property (nonatomic, strong) NSString *videoPath;//视频路径
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
//切换摄像头
-(void)changeVideoWithType:(BOOL)type;
@end