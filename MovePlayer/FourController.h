//
//  FourController.h
//  MovePlayer
//
//  Created by apple on 2017/2/22.
//  Copyright © 2017年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol retunVideoPath <NSObject>
-(void)getVideoPath:(NSString *)path;
@end
@interface FourController : UIViewController
@property (nonatomic, assign)id<retunVideoPath>delegate;
@end
