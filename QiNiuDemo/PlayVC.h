//
//  PlayVC.h
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/18.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerBasedQINiu.h"
@interface PlayVC : UIViewController


@property (nonatomic ,strong)  NSURL  *URL; //推流号码
@property (nonatomic ,strong)  PlayerBasedQINiu *playerQN;
@end
