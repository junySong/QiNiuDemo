//
//  PlayerBasedQINiu.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/16.
//  Copyright © 2016年 Juny_song. All rights reserved.
//


#import "PlayerBasedQINiu.h"


#import <HappyDNS/HappyDNS.h>

//const char *networkStatus[] = {
//    "Not Reachable",
//    "Reachable via WiFi",
//    "Reachable via CELL"
//};


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation PlayerBasedQINiu

#pragma mark ----liftCycle---
- (id)init{
    self = [super init];
    if (self ) {
        [self addObservers];
    }
    return self;
}

- (void)prepareForVideoInView:(UIView *)view{
    self.reconnectCount = 0;
    //通过AVAudioSession可开启以视频为主导的播放模式，
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // 初始化 PLPlayerOption 对象
    PLPlayerOption *option = [PLPlayerOption defaultOption];
    
    // 更改需要修改的 option 属性键所对应的值
    [option setOptionValue:@10 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];
//    [option setOptionValue:@1000 forKey:PLPlayerOptionKeyMaxL1BufferDuration];
//    [option setOptionValue:@1000 forKey:PLPlayerOptionKeyMaxL2BufferDuration];
//    [option setOptionValue:@(YES) forKey:PLPlayerOptionKeyVideoToolbox];
//    [option setOptionValue:@(kPLLogInfo) forKey:PLPlayerOptionKeyLogLevel];
    if (self.URL == nil) {
        NSLog(@"self.URL == nil");
        return;
    }

    // 初始化 PLPlayer
    self.player = [PLPlayer playerWithURL:self.URL option:option];
    self.player.delegateQueue = dispatch_get_main_queue();
    self.player.backgroundPlayEnable = YES; //配置可以后台播放
    self.player.autoReconnectEnable = YES; //配置自动重连
    // 设定代理 (optional)
    self.player.delegate =  self;
    UIView *playerView = self.player.playerView;
    if (!playerView.superview) {
        playerView.contentMode = UIViewContentModeScaleAspectFit;
        playerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleHeight;
    
    //获取视频输出视图并添加为到当前 UIView 对象的 Subview
    [view addSubview:_player.playerView];
    }
    [UIApplication sharedApplication].idleTimerDisabled = YES; //设置不自动锁屏

    [self.player play];
}

- (void)addObservers{
    // 网络状态监控
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
}

- (void)dealloc{
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
    self.player.delegate = nil;
    [self.internetReachability  stopNotifier];
    self.internetReachability = nil;
    
}
#pragma mark -----action------
- (void)playAction{
    // 播放
    [self.player isPlaying] ? [self pauseAction] : [self.player resume] ;
   
    
}
- (void)stopAction{
    // 停止
    [self.player stop];
}
- (void)pauseAction{
    // 暂停
    [self.player pause];
}
- (void)resumeAction{
    // 继续播放
    [self.player resume];
}
- (NSUInteger)totalTime{
    if ((self.player.totalDuration.value != 0)&&(self.player.totalDuration.timescale != 0)) {
        return (self.player.totalDuration.value/self.player.totalDuration.timescale);
    }
    return 0;
}

- (void)seekToTime:(CGFloat)currentTime{
    if (currentTime>1.0||currentTime<0.0 || ( self.player.totalDuration.value == 0) ) {
        return;
    }
    CMTime totlal = self.player.totalDuration;
    CMTime current = CMTimeMake((int)currentTime*(totlal.value), totlal.timescale);//CMTimeMake(第几帧， 帧率)
    [self.player seekTo:current];
}

#pragma mark ----Notification Handler------
#pragma mark 网络状态
- (void)reachabilityChanged:(NSNotification *)notif{
    Reachability *curReach = [notif object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (NotReachable == status) {
        // 对断网情况做处理
        [self pauseAction];
    }
    if (ReachableViaWiFi == status) {
        //转换到WIFI状态,如果是暂停状态，就继续播放，否则就尝试开重新播放
        self.player.status == PLPlayerStatusPaused ? [self resumeAction] : [self.player play] ;
    }
    else if(ReachableViaWWAN == status){
        //转换到移动蜂窝网络，提示用户，同时暂停播放
        //songsong，此时应该有弹出框提示用户
        [self pauseAction];
    }
    NSString *log = [NSString stringWithFormat:@"网络状态提示：Networkt Status: %ld", (long)status];
    NSLog(@"%@", log);
    
}




#pragma mark ------Delegate------
#pragma mark  播放器状态获取

// 实现 <PLPlayerDelegate> 来控制流状态的变更
/**
 告知代理对象播放器状态变更
 
 @param player 调用该方法的 PLPlayer 对象
 @param state  变更之后的 PLPlayer 状态
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state{
    if ([self.delegate respondsToSelector:@selector(playerOfQiNiu:statusDidChange:)]) {
        [self.delegate playerOfQiNiu:self statusDidChange:state];
    }
}

/**
 告知代理对象播放器因错误停止播放
 
 @param player 调用该方法的 PLPlayer 对象
 @param error  携带播放器停止播放错误信息的 NSError 对象
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error{
    
   
    
    if ([self.delegate respondsToSelector:@selector(playerOfQiNiu:stoppedWithError:)]) {
        [self.delegate playerOfQiNiu:self stoppedWithError:error];
    }
}


@end
