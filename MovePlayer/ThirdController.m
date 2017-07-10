//
//  ThirdController.m
//  MovePlayer
//
//  Created by 小龙虾 on 2017/7/6.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ThirdController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ThirdController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property(nonatomic, strong)UIButton *btnClick;
@end

@implementation ThirdController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"视频剪辑";
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
