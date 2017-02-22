//
//  VideoWriter.h
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//
/*
 **本类为文件写入类
 */
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoWriter : NSObject
@property (nonatomic, readonly) NSString *path;
//初始化数据写入对象
+(VideoWriter *)encoderWithPath:(NSString *)path Height:(NSInteger)cy Width:(NSInteger)cx channels:(int)cha samples:(Float64)rate;

/**
 *  完成视频录制时调用
 *
 *  @param handler 完成的回掉block
 */
- (void)finishWithCompletionHandler:(void (^)(void))handler;

/**
 *  通过这个方法写入数据
 *
 *  @param sampleBuffer 写入的数据
 *  @param isVideo      是否写入的是视频
 *
 *  @return 写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;
@end
