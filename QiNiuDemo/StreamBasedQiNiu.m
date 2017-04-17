//
//  StreamBasedQiNiu.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/17.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import "StreamBasedQiNiu.h"

const char *stateNames[] = {
    "Unknow",
    "Connecting",
    "Connected",
    "Disconnecting",
    "Disconnected",
    "Error"
};

//const NSArray *stateNamessss = @[@"未知状态初始化之后",@"连接中。。",@"已连接",@"连接断开中。。",@"已断开",@"发生错误"];
const char *networkStatus[] = {
    "Not Reachable",
    "Reachable via WiFi",
    "Reachable via CELL"
};

#define kReloadConfigurationEnable  0

// 假设在 videoFPS 低于预期 50% 的情况下就触发降低推流质量的操作，这里的 40% 是一个假定数值，你可以更改数值来尝试不同的策略
#define kMaxVideoFPSPercent 0.5

// 假设当 videoFPS 在 10s 内与设定的 fps 相差都小于 5% 时，就尝试调高编码质量
#define kMinVideoFPSPercent 0.05
#define kHigherQualityTimeInterval  10

#define kBrightnessAdjustRatio  1.03
#define kSaturationAdjustRatio  1.03
@implementation StreamBasedQiNiu

#pragma mark --VideoStreamingConfiguration--
#pragma mark --视频编码及推流的配置信息--
/**
 *  视频cofig分为4挡4档是编码后质量最高的
 *
 *  @param PLVideoStreamingConfiguration
 *
 *  @return return value description
 */
/**
*
*  获取推流的编码分辨率
*  @return CGSize 编码的尺寸
*/

- (CGSize)getStreamConfigVideoSize{
    CGSize videoSize = CGSizeMake(480 , 640);
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation <= AVCaptureVideoOrientationLandscapeLeft) {
        if (orientation > AVCaptureVideoOrientationPortraitUpsideDown) {
            videoSize = CGSizeMake(640 , 480);
        }
    }
    return videoSize;
}
/**
 *  UGC情况下，WI-FI环境的默认编码参数
 *  2档
 *  @return PLVideoStreamingConfiguration 对象
 */
- (PLVideoStreamingConfiguration*)videoStreamConfigurationMiddle{
    PLVideoStreamingConfiguration *configuration = nil;
    configuration = [PLVideoStreamingConfiguration configurationWithVideoSize:[UIScreen mainScreen].bounds.size  videoQuality:kPLVideoStreamingQualityMedium1];
    return configuration;
}
/**
 *  UGC情况下，手机WWAN网络环境的默认编码参数
 *  1档
 *  @return PLVideoStreamingConfiguration 对象
 */
- (PLVideoStreamingConfiguration*)videoStreamConfigurationLow{
    PLVideoStreamingConfiguration *configuration = nil;
      configuration = [PLVideoStreamingConfiguration configurationWithVideoSize:[UIScreen mainScreen].bounds.size  videoQuality:kPLVideoStreamingQualityLow2];
    return configuration;
}
/**
 * PGC情况下，WI-FI环境的默认编码参数
 * 4档
 *  @return PLVideoStreamingConfiguration 对象
 */
- (PLVideoStreamingConfiguration*)videoStreamConfigurationhigher{
    PLVideoStreamingConfiguration *configuration = nil;
    configuration = [PLVideoStreamingConfiguration configurationWithVideoSize:[UIScreen mainScreen].bounds.size  videoQuality:kPLVideoStreamingQualityHigh1];
    return configuration;
}
/**
 * PGC情况下，手机WWAN网络环境的默认编码参数
 *
 *  @return PLVideoStreamingConfiguration 对象
 */
- (PLVideoStreamingConfiguration*)videoStreamConfigurationHigh{
    PLVideoStreamingConfiguration *streamConfig = nil;
    streamConfig = [PLVideoStreamingConfiguration configurationWithVideoSize:[UIScreen mainScreen].bounds.size  videoQuality:kPLVideoStreamingQualityMedium2];
    return streamConfig;
}
#pragma mark ---videoCaptureConfigurations--
/**
 *  视频采集的配置信息
 *
 *  @param rate           采集视频数据的帧率，默认为30
 *  @param sessionPresent  采集的视频的 sessionPreset，默认为 AVCaptureSessionPreset640x480
 *
 *  @return PLVideoCaptureConfiguration对象，视频采集的配置信息
 */

- (PLVideoCaptureConfiguration *)VideoCaptureConfigurationWithVideoFrameRate:(NSUInteger)rate sessionPresent:(NSString *)sessionPresent{
    /**
     @brief 采集的视频数据的帧率，默认为 30
     */
    NSUInteger myrate = (rate==0 ? 30 : rate);
    /**
     @brief 采集的视频的 sessionPreset，默认为 AVCaptureSessionPreset640x480
     */
    NSString *mysessionPresent = (sessionPresent == nil? AVCaptureSessionPresetMedium:[sessionPresent copy]);
    PLVideoCaptureConfiguration *captureConfig =  nil;
    captureConfig  =  [[PLVideoCaptureConfiguration alloc] initWithVideoFrameRate:myrate sessionPreset:mysessionPresent previewMirrorFrontFacing:YES previewMirrorRearFacing:NO streamMirrorFrontFacing:YES streamMirrorRearFacing:NO cameraPosition:AVCaptureDevicePositionFront videoOrientation:AVCaptureVideoOrientationPortrait];
    
    return captureConfig;
}
#pragma mark ----AudioCaptureConfiguration---
#pragma mark ----音频采集和编码---
- (PLAudioStreamingConfiguration*)AudioStreamingConfigurationWithSampleRate:(NSUInteger)rate audioBitRate:(PLStreamingAudioBitRate)audioBitRate{
    PLAudioStreamingConfiguration *streamConfig = nil;
    NSUInteger temprate = (rate>0 ? rate : 0);
    PLStreamingAudioSampleRate myrate = [PLAudioStreamingConfiguration mostSimilarSupportedValueWithEncodedAudioSampleRate:temprate];
    
    streamConfig = [[PLAudioStreamingConfiguration alloc]initWithEncodedAudioSampleRate:myrate encodedNumberOfChannels:1 audioBitRate:audioBitRate];
    return streamConfig;
}

#pragma maek --音频设备的设置--

#pragma mark init
-(instancetype)initWithSessionJsonDic:(NSDictionary*)sessionDic Inview:(UIView*)view{
    self = [super init];
    if (sessionDic&&([[sessionDic allValues]count]>0)) {
        
        self.reconnectAfterDelay = 0.5;
        [self addObseversAndInitsessionQueque];
        NSDictionary *streamJSON = [sessionDic copy];
        
        PLStream *stream = [PLStream streamWithJSON:streamJSON];
        stream.streamID = [streamJSON objectForKey:@"id"];
        stream.title = [streamJSON objectForKey:@"title"];
        stream.hubName = [streamJSON objectForKey:@"hub"];
        stream.publishKey = [streamJSON objectForKey:@"publishKey"];
        stream.publishSecurity = [streamJSON objectForKey:@"publishSecurity"];
        stream.disabled = [[streamJSON objectForKey:@"disabled"]  boolValue] ? NO : YES;
        stream.profiles = @[@"480p", @"720p"];
        stream.hosts = [streamJSON objectForKey:@"hosts"];
        
        void (^permissionBlock)(void) = ^{
            dispatch_async(self.sessionQueue, ^{
                //songsong。此处可以动态配置采集的视频的 sessionPreset
                PLVideoCaptureConfiguration *videoCaptureConfiguration = [self VideoCaptureConfigurationWithVideoFrameRate:0 sessionPresent:AVCaptureSessionPresetHigh];
                PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration] ;
                // 视频编码配置
                PLVideoStreamingConfiguration *videoStreamingConfiguration = [self videoStreamConfigurationhigher];
                self.currentStreamConfigIndex = VideoStreamConfigrationHigher;
                // 音频编码配置
                PLAudioStreamingConfiguration *audioStreamingConfiguration = [self AudioStreamingConfigurationWithSampleRate:44100 audioBitRate:PLStreamingAudioBitRate_96Kbps];
                AVCaptureVideoOrientation orientation = (AVCaptureVideoOrientation)(([[UIDevice currentDevice] orientation] <= UIDeviceOrientationLandscapeRight && [[UIDevice currentDevice] orientation] != UIDeviceOrientationUnknown) ? [[UIDevice currentDevice] orientation]: UIDeviceOrientationPortrait);
                // 推流 session
//                self.session = [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration
            self.session = [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
                self.session.captureDevicePosition = AVCaptureDevicePositionFront;
                NSLog(@"versionInfo----%@",[PLCameraStreamingSession versionInfo]);
                self.session.delegate = self;
                self.session.bufferDelegate = self;
                //开启开启推流断开后自动重连机制，默认为NO
//                self.session.autoReconnectEnable = YES;
//                self.session.threshold = 0.5;
//                //开启开启动态调节帧率，默认为NO
//                self.session.dynamicFrameEnable = YES;
                //设置水印图片
//                UIImage *waterMark = [UIImage imageNamed:@"qiniu.png"];
//                [self.session setWaterMarkWithImage:waterMark position:CGPointMake(100, 300)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIView *previewView = self.session.previewView;
                    previewView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
                    | UIViewAutoresizingFlexibleTopMargin
                    | UIViewAutoresizingFlexibleLeftMargin
                    | UIViewAutoresizingFlexibleRightMargin
                    | UIViewAutoresizingFlexibleWidth
                    | UIViewAutoresizingFlexibleHeight;
                    [view insertSubview:previewView atIndex:0];
                  
                });
            });
        };
        
        void (^noAccessBlock)(void) = ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"无用户权限", nil)
                                                                message:NSLocalizedString(@"!", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
          
            
        };
        
        switch ([PLCameraStreamingSession cameraAuthorizationStatus]) {
            case PLAuthorizationStatusAuthorized:
                permissionBlock();
                break;
            case PLAuthorizationStatusNotDetermined: {
                [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
                    granted ? permissionBlock() : noAccessBlock();
                }];
            }
                break;
            default:
                noAccessBlock();
                break;
        }
    }
    else{
        //请设置推流参数
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"设置推流参数", nil)
                                                            message:NSLocalizedString(@"!", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:nil];
        [alertView show];

    }
    return self;
}

-(void)addObseversAndInitsessionQueque{
    self.sessionQueue = dispatch_queue_create("pili.queue.streaming", DISPATCH_QUEUE_SERIAL);
    
    // 网络状态监控
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
    

}

- (void)dealloc{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
    dispatch_sync(self.sessionQueue, ^{
        [self.session destroy];
    });
    self.session = nil;
    self.sessionQueue = nil;
}


#pragma mark -重载视频采集和编码的方法
//
- (void)higherQuality {
    VideoStreamConfigration idx = self.currentStreamConfigIndex;
    if (idx >= VideoStreamConfigrationHigher) {
        return;
    }
    VideoStreamConfigration newIdx = idx + 1;
    PLVideoStreamingConfiguration *newStreamingConfiguration = [self getVideoStreamWithIndex:newIdx];
    PLVideoCaptureConfiguration *newCaptureConfiguration = [self VideoCaptureConfigurationWithVideoFrameRate:0 sessionPresent:AVCaptureSessionPresetiFrame960x540];
    [self.session reloadVideoStreamingConfiguration:newStreamingConfiguration videoCaptureConfiguration:newCaptureConfiguration];
}
//
- (void)lowerQuality {
    VideoStreamConfigration idx = self.currentStreamConfigIndex;
    if (idx <= VideoStreamConfigrationLow) {
        return;
    }
    VideoStreamConfigration newIdx = idx - 1;
    PLVideoStreamingConfiguration *newStreamingConfiguration = [self getVideoStreamWithIndex:newIdx];
    PLVideoCaptureConfiguration *newCaptureConfiguration = [self VideoCaptureConfigurationWithVideoFrameRate:0 sessionPresent:AVCaptureSessionPreset640x480];
    [self.session reloadVideoStreamingConfiguration:newStreamingConfiguration videoCaptureConfiguration:newCaptureConfiguration];
}

- (PLVideoStreamingConfiguration *)getVideoStreamWithIndex:(VideoStreamConfigration)index{
    PLVideoStreamingConfiguration *newStreamConfig = nil;
    switch (index) {
        case VideoStreamConfigrationLow:
            newStreamConfig = [self videoStreamConfigurationLow];
            break;
        case VideoStreamConfigrationMiddle:
            newStreamConfig = [self videoStreamConfigurationMiddle];
            break;
        case VideoStreamConfigrationHigh:
            newStreamConfig = [self videoStreamConfigurationHigh];
            break;
        case VideoStreamConfigrationHigher:
            newStreamConfig = [self videoStreamConfigurationhigher];
            break;
            
        default:
            newStreamConfig = [self videoStreamConfigurationhigher];
            break;
    }
    self.currentStreamConfigIndex = index;
    return newStreamConfig;
}

#pragma mark - Operation

- (void)stopStream {
    dispatch_async(self.sessionQueue, ^{
        self.keyTime = nil;
        [self.session stop];
    });
}
-(void)strt:(void (^)(bool))block{
    block(YES);
}
- (void)startStreamWithFeedback:(void (^)(BOOL))startStreamCallback{
    self.keyTime = nil;
    dispatch_async(self.sessionQueue, ^{
//        [self.session startWithFeedback:^(PLStreamStartStateFeedback feedback) {
//           BOOL success  =  (feedback== PLStreamStartStateSuccess )? YES : NO;
//            startStreamCallback(success);
//        }];
        [self.session startWithPushURL:[NSURL URLWithString:@"rtmp://pili-live-rtmp.newzhibo.cn/newlive/185812"] feedback:^(PLStreamStartStateFeedback feedback) {
            BOOL success  =  (feedback== PLStreamStartStateSuccess )? YES : NO;
                        startStreamCallback(success);

        }];
    });

}
- (void)startStream {
    self.keyTime = nil;
    //    self.actionButton.enabled = NO;
    dispatch_async(self.sessionQueue, ^{
        [self.session startWithFeedback:^(PLStreamStartStateFeedback feedback) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                //                self.actionButton.enabled = YES;
                NSLog(@"%lu",(unsigned long)feedback);
                
            });
        }];
    });
}

- (void)restartStream{
    self.keyTime = nil;
    //    self.actionButton.enabled = NO;
    dispatch_async(self.sessionQueue, ^{
        [self.session restartWithFeedback:^(PLStreamStartStateFeedback feedback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //                self.actionButton.enabled = YES;
                NSLog(@"%lu",(unsigned long)feedback);
            });
        }];
    });
}

- (void)setIsBeatutify:(BOOL)isBeatutify{
    _isBeatutify = isBeatutify;
    dispatch_async(self.sessionQueue, ^{
        [self.session setBeautifyModeOn:isBeatutify];
    });
    
}

- (void)setFlashLight:(BOOL)flashLight{
    _flashLight = flashLight;
    dispatch_async(self.sessionQueue, ^{
        self.session.torchOn = !self.session.isTorchOn;
    });
}
- (void)toggleCameraStream{
    dispatch_async(self.sessionQueue, ^{
        [self.session toggleCamera];
    });
    
}

- (void)destorySteam{
    dispatch_async(self.sessionQueue, ^{
        [self.session destroy];
    });
    
}
#pragma mark - Notification Handler

#pragma mark 网络状态的通知
- (void)reachabilityChanged:(NSNotification *)notif{
    Reachability *curReach = [notif object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (NotReachable == status) {
        // 对断网情况做处理
        [self stopStream];
    }
    if (ReachableViaWiFi == status) {
        //转换到WIFI状态,如果是连接状态，就快速重连，否则就尝试开始连接
        if (_currentStreamConfigIndex != VideoStreamConfigrationHigher) {
           
        }
        if ([self.session isRunning]) {
//            [self.session restartWithCompleted:^(BOOL success) {
//                
//            }];
            [self.session restartWithFeedback:^(PLStreamStartStateFeedback feedback) {
                
            }];
        }else{
            [self startStream];
        }
    }
    else if(ReachableViaWWAN == status){
        //转换到移动蜂窝网络，提示用户，同时暂停推流
        //songsong，此时应该有弹出框提示用户
        [self stopStream];
    }
    NSString *log = [NSString stringWithFormat:@"网络状态提示：Networkt Status: %s", networkStatus[status]];
    NSLog(@"%@", log);
    
}

#pragma mark 推流被迫中断的监听
- (void)handleInterruption:(NSNotification *)notification {
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification");
        
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"InterruptionTypeBegan");
        } else {
            // the facetime iOS 9 has a bug: 1 does not send interrupt end 2 you can use application become active, and repeat set audio session acitve until success.  ref http://blog.corywiles.com/broken-facetime-audio-interruptions-in-ios-9
            NSLog(@"InterruptionTypeEnded");
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];
        }
    }
}

#pragma mark - <PLStreamingSendingBufferDelegate>

/*!
 @method     streamingSessionSendingBufferDidFull:
 @abstract   当发送队列包满时，会触发该队列已满的回调。
 
 @param      session 调用该代理方法的 session 对象
 
 @since      v1.0.0
 */
- (void)streamingSessionSendingBufferDidFull:(id)session {
    NSString *log = @"Buffer is full";
    NSLog(@"%@", log);
   
    
}
/*!
 @method     streamingSessionSendingBufferDidEmpty:
 @abstract   当发送队列从有数据变为无数据时，会触发该队列为空的回调。
 
 @param      session 调用该代理方法的 session 对象
 
 @since      v1.0.0
 */
- (void)streamingSessionSendingBufferDidEmpty:(id)session{
    
}


#pragma mark - <PLCameraStreamingSessionDelegate>

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", stateNames[state]];
    NSLog(@"%@", log);
   
    
    // 除 PLStreamStateError 外的其余状态会回调在这个方法
    // 这个回调会确保在主线程，所以可以直接对 UI 做操作
    if (PLStreamStateConnected == state) {
//        [self.actionButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
    } else if (PLStreamStateDisconnected == state) {
//        [self.actionButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];
    }
}

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session didDisconnectWithError:(NSError *)error {
    NSString *log = [NSString stringWithFormat:@"Stream State: Error. %@", error];
    NSLog(@"%@", log);
    
    // PLStreamStateError 都会回调在这个方法
    // 尝试重连，注意这里需要你自己来处理重连尝试的次数以及重连的时间间隔,如果重连成功，重连时间间隔设置为初始的0.5，否则重连时间加倍
//    if (self.reconnectAfterDelay>10) {
//        return;
//    }
    CGFloat delay = self.reconnectAfterDelay>0 ? self.reconnectAfterDelay>0 : 0.5;
    dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW,  delay*NSEC_PER_SEC);
    
    dispatch_after(time, dispatch_get_main_queue(), ^{
        //执行操作
        [self.session startWithFeedback:^(PLStreamStartStateFeedback feedback) {
            NSLog(@"after--conecting-- %.2f----",delay);
        //如果推流成功或者是正在推流中，重置推流的时间间隔（默认是0.5）
            if ((feedback == PLStreamStartStateSuccess) || (feedback == PLStreamStartStateSessionStillRunning)   ) {
                self.reconnectAfterDelay = 0.5;
            }else{
                self.reconnectAfterDelay = 2* self.reconnectAfterDelay ;
            }
            
        }];
    });

  
}

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    NSString *log = [NSString stringWithFormat:@"PLStreamStatus---%@---", status];
    NSLog(@"%@", log);
    
    
#if kReloadConfigurationEnable
    NSDate *now = [NSDate date];
    if (!self.keyTime) {
        self.keyTime = now;
    }
    
    double expectedVideoFPS = (double)self.session.videoConfiguration.videoFrameRate;
    double realtimeVideoFPS = status.videoFPS;
    if (realtimeVideoFPS < expectedVideoFPS * (1 - kMaxVideoFPSPercent)) {
        // 当得到的 status 中 video fps 比设定的 fps 的 50% 还小时，触发降低推流质量的操作
        self.keyTime = now;
        
        [self lowerQuality];
    } else if (realtimeVideoFPS >= expectedVideoFPS * (1 - kMinVideoFPSPercent)) {
        if (-[self.keyTime timeIntervalSinceNow] > kHigherQualityTimeInterval) {
            self.keyTime = now;
            
            [self higherQuality];
        }
    }
#endif  // #if kReloadConfigurationEnable
}

- (void)reloadCofig{
    PLVideoCaptureConfiguration *videoCaptureConfiguration = [self VideoCaptureConfigurationWithVideoFrameRate:0 sessionPresent:AVCaptureSessionPresetiFrame960x540];
    // 视频编码配置
    PLVideoStreamingConfiguration *videoStreamingConfiguration = [self videoStreamConfigurationhigher];
    
    [self.session reloadVideoStreamingConfiguration:videoStreamingConfiguration videoCaptureConfiguration:videoCaptureConfiguration];
}
@end
