//
//  streamVC.h
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/18.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamBasedQiNiu.h"
@interface streamVC : UIViewController

@property (nonatomic, strong) NSDictionary *streamJsonDic;
@property (nonatomic, strong) StreamBasedQiNiu *streamQiNiu;

@end
