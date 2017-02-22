//
//  VideoWriter.m
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "VideoWriter.h"


@interface VideoWriter ()
@property(nonatomic, strong)AVAssetWriter *writer;            //媒体写入对象
@property(nonatomic, strong)AVAssetWriterInput *videoWriter;  //视频写入
@property(nonatomic, strong)AVAssetWriterInput *audioWriter;  //音频写入
@property(nonatomic, copy)NSString *path;                     //写入路径
@end
@implementation VideoWriter
+(VideoWriter *)encoderWithPath:(NSString *)path Height:(NSInteger)cy Width:(NSInteger)cx channels:(int)cha samples:(Float64)rate
{
    VideoWriter *videoWriter = [[VideoWriter alloc] initWithPath:path Height:cy Width:cx channels:cha samples:rate];
    return videoWriter;
}

-(instancetype)initWithPath:(NSString *)path Height:(NSInteger)cy Width:(NSInteger)cx channels:(int)ch samples:(Float64)rate
{
    self = [super init];
    if (self) {
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
    return self;
}

//初始化视频输入
-(void)initVideoInputHeight:(NSInteger)cy width:(NSInteger)cx
{
    //录制视频的一些配置，分辨率，编码方式等等
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264, AVVideoCodecKey,
                              [NSNumber numberWithInteger: cx], AVVideoWidthKey,
                              [NSNumber numberWithInteger: cy], AVVideoHeightKey,
                              nil];
    //初始化视频写入类
    self.videoWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    self.videoWriter.expectsMediaDataInRealTime = YES;
    //将视频源输入
    [self.writer addInput:self.videoWriter];

}

//初始化音频输出
-(void)initAudioInputChannels:(int)ch samples:(Float64)rate
{
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [ NSNumber numberWithInt: ch], AVNumberOfChannelsKey,
                              [ NSNumber numberWithFloat: rate], AVSampleRateKey,
                              [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
                              nil];
    //初始化音频写入类
    self.audioWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    self.audioWriter.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    [self.writer addInput:self.audioWriter];
}

//完成视频录制时调用
-(void)finishWithCompletionHandler:(void (^)(void))handler
{
    [self.writer finishWritingWithCompletionHandler:handler];
}

//通过这个方法写入数据
-(BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo
{
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态为未知，保证视频先写入
        if (self.writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (self.writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@",_writer.error.localizedDescription);
            return NO;
        }
        //判断是否是视频
        if (isVideo) {
            //视频输入是否准备接受更多的媒体数据
            if (self.videoWriter.readyForMoreMediaData == YES) {
                //拼接数据
                [self.videoWriter appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }else{
            //音频输入是否准备接受更多的媒体数据
            if (self.audioWriter.readyForMoreMediaData) {
                //拼接数据
                [self.audioWriter appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }
    }
    return NO;
}

@end
