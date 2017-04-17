//
//  JSPlayerViewController.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/15.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import "JSPlayerViewController.h"

#import <PLPlayerKit/PLPlayerKit.h>
#import <HappyDNS/HappyDNS.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface JSPlayerViewController ()<PLPlayerDelegate>


@property (nonatomic, strong) PLPlayer *player;
@property (nonatomic, assign) int reconnectCount;


@end

@implementation JSPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.reconnectCount = 0;
    //音频播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // 初始化 PLPlayerOption 对象
    PLPlayerOption *option = [PLPlayerOption defaultOption];
    
    // 更改需要修改的 option 属性键所对应的值
    [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];
    [option setOptionValue:@1000 forKey:PLPlayerOptionKeyMaxL1BufferDuration];
    [option setOptionValue:@1000 forKey:PLPlayerOptionKeyMaxL2BufferDuration];
    [option setOptionValue:@(YES) forKey:PLPlayerOptionKeyVideoToolbox];
    [option setOptionValue:@(kPLLogInfo) forKey:PLPlayerOptionKeyLogLevel];
    [option setOptionValue:[QNDnsManager new] forKey:PLPlayerOptionKeyDNSManager];
    
    if (self.URL == nil) {
        NSLog(@"self.URL == nil");
        return;
    }
    // 初始化 PLPlayer
    self.player = [PLPlayer playerWithURL:self.URL option:option];
    
    // 设定代理 (optional)
    self.player.delegate = self;
    
    //获取视频输出视图并添加为到当前 UIView 对象的 Subview
    UIView *playerView = self.player.playerView;
    if (!playerView.superview) {
        playerView.contentMode = UIViewContentModeScaleAspectFill;
                playerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
                | UIViewAutoresizingFlexibleTopMargin
                | UIViewAutoresizingFlexibleLeftMargin
                | UIViewAutoresizingFlexibleRightMargin
                | UIViewAutoresizingFlexibleWidth
                | UIViewAutoresizingFlexibleHeight;
        
        //获取视频输出视图并添加为到当前 UIView 对象的 Subview
        [self.view addSubview:_player.playerView];
    }
    
    [self.player play];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark -----lifecycle-------

#pragma mark -----action------
- (void)playAction:(UIButton*)sender{
    // 播放
    [self.player play];
}
- (void)stopAction:(UIButton*)sender{
    // 停止
    [self.player stop];
}
- (void)pauseAction:(UIButton*)sender{
    // 暂停
    [self.player pause];
}
- (void)resumeAction:(UIButton*)sender{
    // 继续播放
    [self.player resume];
}

#pragma mark ------Delegate------
#pragma mark  播放器状态获取

// 实现 <PLPlayerDelegate> 来控制流状态的变更
- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
    // 这里会返回流的各种状态，你可以根据状态做 UI 定制及各类其他业务操作
    // 除了 Error 状态，其他状态都会回调这个方法
}

- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
    // 当发生错误时，会回调这个方法
    
    [self tryReconnect:error];
}
- (void)tryReconnect:(nullable NSError *)error {
    if (self.reconnectCount < 3) {
        _reconnectCount ++;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:[NSString stringWithFormat:@"错误 %@，播放器将在%.1f秒后进行第 %d 次重连", error.localizedDescription,0.5 * pow(2, self.reconnectCount - 1), _reconnectCount] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * pow(2, self.reconnectCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.player play];
        });
    }else {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(self) wself = self;
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK"
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction *action) {
                                                               __strong typeof(wself) strongSelf = wself;
                                                               [strongSelf.navigationController performSelectorOnMainThread:@selector(popViewControllerAnimated:) withObject:@(YES) waitUntilDone:NO];
                                                           }];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        NSLog(@"%@", error);
    }
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
