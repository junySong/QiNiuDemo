//
//  JSSteamViewController.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/11.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import "JSSteamViewController.h"
#import <PLMediaStreamingKit/PLCameraStreamingKit.h>





@interface JSSteamViewController ()<PLCameraStreamingSessionDelegate,PLStreamingSendingBufferDelegate>
@property (nonatomic, strong) PLCameraStreamingSession  *session;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) NSDate    *keyTime;//关键帧的时间

@property (nonatomic, strong) UISlider *zoomSlider;



@end

@implementation JSSteamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.sessionQueue = dispatch_queue_create("pili.queue.streaming", DISPATCH_QUEUE_SERIAL);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor orangeColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor cyanColor];
    [button setTitle:@"start" forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 100, 44);
//    button.center = self.view.center;
    [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.backgroundColor = [UIColor purpleColor];
    [button1 setTitle:@"toggle" forState:UIControlStateNormal];
    button1.frame = CGRectMake(120, 0, 100, 44);

    [button1 addTarget:self action:@selector(actiontogglePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    [self AddAuthor];//获取授权
    
    _zoomSlider = [[UISlider alloc]initWithFrame:({CGRect rect = CGRectMake(10, 60, 200, 10);
                              rect;})];
    [_zoomSlider addTarget:self action:@selector(zoomSliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
    _zoomSlider.minimumValue = 1.0;
    _zoomSlider.maximumValue = MIN(5, self.session.videoActiveFormat.videoMaxZoomFactor);
    [self.view addSubview:_zoomSlider];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{


    [self destoryStream];
    self.session = nil;
    
}

#pragma mark liftcycle
- (void)AddAuthor{
 
    /**
     *  没有授权的情况
     */
  void (^noPermissionBlock)(void) = ^{ // 处理未授权情况
      NSLog(@"noPermission");
  };
    
        /**
     *  授权后执行
     */
    // streamJSON 是从服务端拿回的
    //
    // 从服务端拿回的 streamJSON 结构如下：
    //    @{@"id": @"stream_id",
    //      @"title": @"stream_title",
    //      @"hub": @"hub_id",
    //      @"publishKey": @"publish_key",
    //      @"publishSecurity": @"dynamic", // or static
    //      @"disabled": @(NO),
    //      @"profiles": @[@"480p", @"720p"],    // or empty Array []
    //      @"hosts": @{
    //            ...
    //      }
    NSString *jsonstring = @"{\"id\":\"z1.newlive.Juny\",\"createdAt\":\"2016-08-15T11:02:03.038+08:00\",\"updatedAt\":\"2016-08-15T11:02:03.038+08:00\",\"title\":\"Juny\",\"hub\":\"newlive\",\"disabledTill\":0,\"disabled\":false,\"publishKey\":\"a7b7642cdd38fb2e\",\"publishSecurity\":\"dynamic\",\"hosts\":{\"publish\":{\"rtmp\":\"pili-publish.newzhibo.cn\"},\"live\":{\"hdl\":\"pili-live-hdl.newzhibo.cn\",\"hls\":\"pili-live-hls.newzhibo.cn\",\"http\":\"pili-live-hls.newzhibo.cn\",\"rtmp\":\"pili-live-rtmp.newzhibo.cn\",\"snapshot\":\"pili-live-snapshot.newzhibo.cn\"},\"playback\":{\"hls\":\"10002b9.playback1.z1.pili.qiniucdn.com\",\"http\":\"10002b9.playback1.z1.pili.qiniucdn.com\"},\"play\":{\"http\":\"pili-live-hls.newzhibo.cn\",\"rtmp\":\"pili-live-rtmp.newzhibo.cn\"}}}";
    
    NSError *error;
    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:[jsonstring dataUsingEncoding:NSUTF8StringEncoding]options:NSJSONReadingMutableContainers error:&error];
    
    NSDictionary *streamJSON = [responseDic copy];
    
    PLStream *stream = [PLStream streamWithJSON:streamJSON];
    stream.streamID = [streamJSON objectForKey:@"id"];//用于唯一标示流的ID
    stream.title = [streamJSON objectForKey:@"title"];//流标题
    stream.hubName = [streamJSON objectForKey:@"hub"];//流所归属的hub的名字
    stream.publishKey = [streamJSON objectForKey:@"publishKey"];//推流时用于鉴权的秘钥
    stream.publishSecurity = [streamJSON objectForKey:@"publishSecurity"];//鉴权类型
    stream.disabled = [streamJSON objectForKey:@"disabled"];//流是否已被禁用
    
    /*!
     @property   profiles
     @abstract   包含的转码类型。
     
     @since      v1.0.0
     */
    stream.hosts = [streamJSON objectForKey:@"hosts"];//所有的相关域名
   

    
   
    void (^permissionBlock)(void) = ^{
        dispatch_async(self.sessionQueue, ^{
        PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
        PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
        PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
        PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
        AVCaptureVideoOrientation orientation = (AVCaptureVideoOrientation)(([[UIDevice currentDevice] orientation] <= UIDeviceOrientationLandscapeRight && [[UIDevice currentDevice] orientation] != UIDeviceOrientationUnknown) ? [[UIDevice currentDevice] orientation]: UIDeviceOrientationPortrait);
        //推流session
//        self.session = [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:stream videoOrientation:orientation];
            self.session = [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
       
        
        self.session.delegate = self;
        self.session.bufferDelegate = self;
        [self.view insertSubview:self.session.previewView atIndex:0];
        
//        [self startSteam];
        });
    };
   
      // 检查摄像头是否有授权
      PLAuthorizationStatus status = [PLCameraStreamingSession cameraAuthorizationStatus];
      
      if (PLAuthorizationStatusNotDetermined == status) {
          [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
              // 回调确保在主线程，可以安全对 UI 做操作
              granted ? permissionBlock() : noPermissionBlock();
          }];
      } else if (PLAuthorizationStatusAuthorized == status) {
          permissionBlock();
      } else {
          noPermissionBlock();
      }
  

  
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}
#pragma mark handlesession
/**
 *  开始推流
 */
- (void)startSteam{
    if ([self.session isRunning]) {
        return;
    }
    // 开始推流，无论 security policy 是 static 还是 dynamic，都无需再单独计算推流地址
    __weak __typeof(&*self)weakSelf = self;
//    [self.session startWithCompleted:^(BOOL success) {
//        // 这里的代码在主线程运行，所以可以放心对 UI 控件做操作
//        if (success) {
//        
//            // 连接成功后的处理
//            // 成功后，在这里才可以读取 self.session.pushURL，start 失败和之前不能确保读取到正确的 URL
//        } else {
//            // 连接失败后的处理
//            NSLog(@"eee");
//        }
//    }];
    [self.session startWithPushURL:[NSURL URLWithString:@"rtmp://pili-publish.newzhibo.cn/newlive/185812?key=c6ebd19ab61b6b19"] feedback:^(PLStreamStartStateFeedback feedback) {
        if (feedback) {
            
                        // 连接成功后的处理
                        // 成功后，在这里才可以读取 self.session.pushURL，start 失败和之前不能确保读取到正确的 URL
                    } else {
                        // 连接失败后的处理
                        NSLog(@"eee");
                    }
    }];
}

/**
 *  快速重新推流
 * @param handler 流连接的结果会通过该回调方法返回，如果流连接成功将返回 YES，如果连接失败或当前流正在连接或已经连接将返回 NO
 *
 * @discussion 当处于正在推流过程中时，由于业务原因（如用户网络从 3G/4G 切换到 WIFI）需要快速重新开始推流时，可以调用该方法；非推流过程中调用该方法会直接返回；
 *
 */
- (void)rest{
    [self.session restartWithCompleted:^(BOOL success) {
        
    }];
}

/**
 *  结束推流
 */
- (void)stopStream{
    [self.session stop];
}
/**
 *  摧毁推流
 */

- (void)destoryStream{
    [self.session destroy];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark actions
- (void)actionButtonPressed:(id)sender {
    [self startSteam];
}

- (void)actiontogglePressed:(UIButton*)sender{
    dispatch_async(self.sessionQueue, ^{
        [self.session toggleCamera];
    });
}
#pragma mark slide
//进度条
- (void)zoomSliderValueDidChange:(id)sender {
    self.session.videoZoomFactor = self.zoomSlider.value;
    [self.session setBeautify:0.5];
}
#pragma mark -----Delegate-------

#pragma mark PLCameraStreamingSessionDelegate
- (void)cameraStreamingSession:(PLCameraStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    // 当流状态变更为非 Error 时，会回调到这里
}
- (void)cameraStreamingSession:(PLCameraStreamingSession *)session didDisconnectWithError:(NSError *)error {
    // 当流状态变为 Error, 会携带 NSError 对象回调这个方法
}
- (void)streamingSession:(PLStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    // 当开始推流时，会每间隔 3s 调用该回调方法来反馈该 3s 内的流状态，包括视频帧率、音频帧率、音视频总码率
}

@end
