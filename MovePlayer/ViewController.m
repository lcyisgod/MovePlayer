//
//  ViewController.m
//  MovePlayer
//
//  Created by apple on 2017/2/17.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ViewController.h"
#import "SecondController.h"
#import "ThirdController.h"
#import "FourController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic, assign)int isVideo;         //是否录制视频 0:拍照  1:录制视频
@property(nonatomic, strong)UIImagePickerController *imagepicker;
@property(nonatomic, strong)UIImageView *photo;
@property(nonatomic, strong)UIButton *btnClick;  //视频录制按钮
@property(nonatomic, strong)AVPlayer *player;    //播放器,用于录制完视频后的播放
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationItem setTitle:@"AVPlayer"];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pushNext:)]];
    //通过这里设置当前程序是拍照还是录制视频
    _isVideo = YES;
    
    self.btnClick = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x-40, self.view.center.y-30, 80, 60)];
    [self.btnClick setBackgroundColor:[UIColor redColor]];
    [self.btnClick setTitle:@"录制" forState:UIControlStateNormal];
    [self.btnClick setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.btnClick.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.btnClick addTarget:self action:@selector(startMp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnClick];
    
    
    
    self.photo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 280)];
    self.photo.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.photo];
}

-(void)pushNext:(UIBarButtonItem *)sender
{
//    ThirdController *secVC = [ThirdController new];
//    [self presentViewController:secVC animated:YES completion:nil];
    [self presentViewController:[FourController new] animated:YES completion:nil];
}

-(void)startMp:(UIButton *)sender
{
    [self presentViewController:self.imagepicker animated:YES completion:nil];
}

-(UIImagePickerController *)imagepicker
{
    if (!_imagepicker) {
        _imagepicker = [UIImagePickerController new];
        _imagepicker.sourceType = UIImagePickerControllerSourceTypeCamera;    //指定来源摄像头
        _imagepicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;  //指定厚重摄像头
        if (self.isVideo) {
            _imagepicker.mediaTypes = @[(NSString *)kUTTypeMovie];            //指定媒体类型
            _imagepicker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;  //指定视频质量
            _imagepicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;  //设置摄像头模式
            //设置视频最大长度
            _imagepicker.videoMaximumDuration = 30.0;
            
        }
        _imagepicker.allowsEditing = YES;
        _imagepicker.delegate = self;
    }
    return _imagepicker;
}

//代理方法
//完成
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    NSString *path = [url path];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        //保存视频到相册
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinshSaveWithError:contextInfo:), nil);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

//取消
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"取消");
}

//保存视频后的回调
-(void)video:(NSString *)videoPah didFinshSaveWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"保存失败%@",error.localizedDescription);
    }else{
        NSURL *url = [NSURL fileURLWithPath:videoPah];
        _player = [AVPlayer playerWithURL:url];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        //设置填充方式，否则无法修改宽度
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.photo.frame.size.height);
        [self.photo.layer addSublayer:playerLayer];
        [_player play];
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
