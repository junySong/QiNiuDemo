//
//  PlayVC.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/18.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import "PlayVC.h"

@interface PlayVC ()<PlayerBasedQINiuDelegate>
@property (nonatomic, strong) UIView *playView;
@property (nonatomic, assign) BOOL isRotate;

@end

@implementation PlayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    _playView = [[UIView alloc]initWithFrame:self.view.bounds];
    _playView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_playView];
    [self PlayPrepare];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.backgroundColor = [UIColor blueColor];
    [button1 setTitle:@"旋转" forState:UIControlStateNormal];
    button1.frame = CGRectMake(0, 200, 100, 44);
    [button1 addTarget:self action:@selector(actionbutton1Pressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
   //    设置窗口亮度大小  范围是0.1 -1.0
    [[UIScreen mainScreen] setBrightness:0.5];
    //设置屏幕常亮
    [UIApplication sharedApplication].idleTimerDisabled = YES;
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
- (void)PlayPrepare{
    self.playerQN = [[PlayerBasedQINiu alloc]init];
    self.playerQN.URL = self.URL;
    [_playerQN prepareForVideoInView:_playView];
}

- (void)actionbutton1Pressed : (UIButton *)sender{
    self.isRotate = !self.isRotate;
    self.isRotate ? [self rotate] : [self nomal];
}

- (void)nomal{
    [UIView animateWithDuration:0.1 animations:^{
        
         _playView.transform = CGAffineTransformMakeRotation( 0);
    } completion:^(BOOL finished) {
        
    }];
   
}

- (void)rotate{
    
    [UIView animateWithDuration:0.1 animations:^{
        _playView.transform = CGAffineTransformMakeRotation(  M_PI_2);
    } completion:^(BOOL finished) {
        
    }];
}


- (void)playerOfQiNiu:( PlayerBasedQINiu *)qiNiuPlayer statusDidChange:(PLPlayerStatus)state{
    
}
/**
 告知代理对象播放器因错误停止播放
 
 @param player 调用该方法的 PLPlayer 对象
 @param error  携带播放器停止播放错误信息的 NSError 对象
 
 @since v1.0.0
 */

- (void)playerOfQiNiu:( PlayerBasedQINiu *)qiNiuPlayer stoppedWithError:( NSError *)error{
    UIAlertController  *ac = [UIAlertController alertControllerWithTitle:@"出错啦" message:@"error" preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:ac animated:YES completion:nil];

}


@end
