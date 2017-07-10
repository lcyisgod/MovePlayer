//
//  SecondController.m
//  MovePlayer
//
//  Created by 小龙虾 on 2017/7/4.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "SecondController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
@interface SecondController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property(nonatomic, strong)UIButton *btnClick;
@property(nonatomic, strong)MPMoviePlayerViewController *playerVC;
@property(nonatomic, strong)AVAssetExportSession *exportSession;
@end

@implementation SecondController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"视频水印";
    [self.view addSubview:self.btnClick];
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

-(void)locaVideo:(UIButton *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes =[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    [self presentViewController:picker animated:YES completion:nil];
}

//添加水印:videoPath是本地水印的地址，fileName是合成后视频的名称,prame是要合成的水印的对象(图片或者文字)
- (void)AVsaveVideoPath:(NSURL*)videoPath WithPrame:(NSDictionary *)prame WithFileName:(NSString*)fileName
{
    if (!videoPath) {
        return;
    }
    //1 创建AVAsset实例 AVAsset包含了video的所有信息 videoPath输入视频的路径
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    //初始化视频媒体文件
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoPath options:opts];
    //开始时间，这个时间记得在endtime后面减去，否则会造成在视频结束后产生黑屏问题
    CMTime startTime = CMTimeMakeWithSeconds(1, 2);
    CMTime endTime = CMTimeMakeWithSeconds(videoAsset.duration.value/videoAsset.duration.timescale-1, videoAsset.duration.timescale);
    //声音采集
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:videoPath options:opts];
    //2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    //工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    //3 视频通道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
    [videoTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    //音频通道
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                        ofTrack:audioAssetTrack
                         atTime:kCMTimeZero error:nil];
    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction
                                                             videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
    //3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //是对缩放和旋转进行限制吗？
    //UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.85 atTime:endTime];
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    //AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    //添加后视频播放的帧数？
    //这个frameDuration设置值必须要合适，比例太大会造成卡顿现象
    mainCompositionInst.frameDuration = CMTimeMake(1, 50);
    [self applyVideoEffectsToComposition:mainCompositionInst withPrame:prame size:CGSizeMake(renderWidth, renderHeight) videoAsset:videoAsset];
    
    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",fileName]];
    unlink([myPathDocs UTF8String]);
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    //监听视频处理进度？
//    CADisplayLink *dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
//    [dlink setFrameInterval:15];
//    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//    [dlink setPaused:NO];
    __weak typeof(self) weakSelf = self;
    // 5 - 视频文件输出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
            [[weakSelf.playerVC moviePlayer] prepareToPlay];
            
            [weakSelf presentMoviePlayerViewControllerAnimated:weakSelf.playerVC];
            [[weakSelf.playerVC moviePlayer] play];
        });
    }];
}

//此方法添加具体的水印，此处提供2个demo。分别是一张图片水印和2张图片一个文字水印
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition
                             withPrame:(NSDictionary *)prame
                                  size:(CGSize)size
                            videoAsset:(AVAsset *)asset
{
    CALayer *overlayLayer = [CALayer layer];
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    
    //第一张图片水印
    UIImage *img = [prame objectForKey:@"firstImg"];
    CALayer *imgLayer = [CALayer layer];
    imgLayer.contents = (id)img.CGImage;
    imgLayer.bounds = CGRectMake(0, 0, 200, 200);
    imgLayer.cornerRadius = 100;
    imgLayer.masksToBounds = YES;
    imgLayer.opacity = 0;
    imgLayer.position = CGPointMake(size.width/2.0, size.height/2.0);
    
    
    //判断是否有文字
    if ([prame objectForKey:@"title"]) {
        UIFont *font = [UIFont systemFontOfSize:30.0];
        CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
        [subtitle1Text setFontSize:30];
        [subtitle1Text setString:[prame objectForKey:@"title"]];
        [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
        [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
        subtitle1Text.masksToBounds = YES;
        subtitle1Text.cornerRadius = 23.0f;
        [subtitle1Text setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor];
        CGSize textSize = [[prame objectForKey:@"title"] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
        [subtitle1Text setFrame:CGRectMake(50, 100, textSize.width+20, textSize.height+10)];
        [overlayLayer addSublayer:subtitle1Text];
    }
    
    //判断是否有第二张图片
    if ([prame objectForKey:@"secondImg"]) {
        UIImage *img = [prame objectForKey:@"secondImg"];
        CALayer *coverImgLayer = [CALayer layer];
        coverImgLayer.contents = (id)img.CGImage;
        coverImgLayer.bounds =  CGRectMake(50, 200,200, 200);
        coverImgLayer.position = CGPointMake(size.width/4.0, size.height/4.0);
        [parentLayer addSublayer:coverImgLayer];
    }
    
    [overlayLayer addSublayer:imgLayer];
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    //水印出现的时间
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation setDuration:1];
    [animation setFromValue:[NSNumber numberWithFloat:0.0]];
    [animation setToValue:[NSNumber numberWithFloat:1]];
    [animation setBeginTime:asset.duration.value/asset.duration.timescale-5.0f];
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    [imgLayer addAnimation:animation forKey:@"animateOpacity"];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}


#pragma mark - Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[UIImage imageNamed:@"img1.jpg"] forKey:@"firstImg"];
        [dict setObject:@"水印文字" forKey:@"title"];
        [weakSelf AVsaveVideoPath:[info objectForKey:UIImagePickerControllerMediaURL] WithPrame:dict WithFileName:@"testVideo"];
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
