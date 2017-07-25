//
//  ThirdController.m
//  MovePlayer
//
//  Created by 小龙虾 on 2017/7/6.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ThirdController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ThirdController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property(nonatomic, strong)UIButton *btnClick;
@property(nonatomic, strong)UIButton *btnClick1;
@property(nonatomic, strong)MPMoviePlayerViewController *playerVC;
@end

@implementation ThirdController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"截取视频";
    [self.view addSubview:self.btnClick];
    [self.view addSubview:self.btnClick1];
}

-(UIButton *)btnClick
{
    if (!_btnClick) {
        self.btnClick = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-60, self.view.center.y-30, 120, 60)];
        [self.btnClick setTitle:@"本地视频" forState:UIControlStateNormal];
        [self.btnClick setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.btnClick addTarget:self action:@selector(locaVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnClick;
}

-(UIButton *)btnClick1
{
    if (!_btnClick1) {
        self.btnClick1 = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-60, self.view.center.y-100, 120, 60)];
        [self.btnClick1 setTitle:@"播放" forState:UIControlStateNormal];
        [self.btnClick1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.btnClick1 addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnClick1;
}

-(void)locaVideo:(UIButton *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes =[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)playVideo:(UIButton *)sender
{
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingString:@"MixVideo.mov"];
    self.playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:videoPath]];
    [[self.playerVC moviePlayer] prepareToPlay];
    [self presentMoviePlayerViewControllerAnimated:self.playerVC];
    [[self.playerVC moviePlayer] play];

}



-(void)videoCatWithUrl:(NSURL *)videoUrl andCaptureRange:(NSRange)videoRange
{
    //AVURLAsset此类主要用于获取媒体信息,包括视频,声音等
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //CMTimeRangeMake(start, duration),start起始时间，duration时长，都是CMTime类型
    //CMTimeMake(int64_t value, int32_t timescale)，返回CMTime，value视频的一个总帧数，timescale是指每秒视频播放的帧数，视频播放速率，（value / timescale）才是视频实际的秒数时长，timescale一般情况下不改变，截取视频长度通过改变value的值
    //CMTimeMakeWithSeconds(Float64 seconds, int32_t preferredTimeScale)，返回CMTime，seconds截取时长（单位秒），preferredTimeScale每秒帧数
    
    //开始位置startTime
    CMTime startTime =  CMTimeMakeWithSeconds(videoRange.location, videoAsset.duration.timescale);
    //截取长度videoDuration
    CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, videoAsset.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
    
    //视频采集compositionVideoTrack
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    //TimeRange截取的范围长度
    //ofTrack来源
    //atTime插放在视频的时间位置
    [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:([videoAsset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero error:nil];
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MixVideo.mov"];
    //剪辑后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    
    //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
    assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    assetExportSession.outputURL = outPutUrl;
    //输出文件是否网络优化
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"剪成功了吗?");
    }];
}

#pragma mark - Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf videoCatWithUrl:[info objectForKey:UIImagePickerControllerMediaURL] andCaptureRange:NSMakeRange(0, 10.0)];
    }];
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
