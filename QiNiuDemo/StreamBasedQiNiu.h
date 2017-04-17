//
//  StreamBasedQiNiu.h
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/17.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <asl.h>
#import <PLMediaStreamingKit/PLCameraStreamingKit.h>

typedef NS_ENUM(NSUInteger,VideoStreamConfigration) {

    VideoStreamConfigrationLow = 1,
    VideoStreamConfigrationMiddle = 2,
    VideoStreamConfigrationHigh = 3,
    VideoStreamConfigrationHigher = 4,
    videoStreamConfigrrationDefault = VideoStreamConfigrationHigher,
    
};

@interface StreamBasedQiNiu : NSObject
<
PLCameraStreamingSessionDelegate,
PLStreamingSendingBufferDelegate
>
@property (nonatomic, strong) PLCameraStreamingSession  *session;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) NSDate    *keyTime;

@property (nonatomic, assign) CGFloat reconnectAfterDelay;//重连的时间间隔
@property (nonatomic, assign)VideoStreamConfigration currentStreamConfigIndex; //当前的streamConfigIndex；总共4档

@property (nonatomic, assign) BOOL isBeatutify;  //是否开启美颜
@property (nonatomic, assign) BOOL flashLight;  //是否开启闪光
@property (nonatomic, assign) BOOL toggle;  // 是否是后置摄像头

#pragma mark init
/*!
 @class      sessionDic
 @abstract   一个 sessionDic 对象可以通过从 Pili API 创建获得。
 
 @discussion 一个 sessionDic 对象以 JSON 形式表达会包含一下信息：
 @code
 {
 id: 'STREAM_ID',
 title: 'STREAM_TITLE'.
 hub: 'HUB_NAME',
 publishKey: 'PUBLISH_KEY',
 publishSecurity: 'PUBLISH_SECURITY',
 profiles: ['480p', '720p'],
 hosts: {
 ...
 },
 disabled: false
 }
 @endcode
 
 @since      v1.0.0
 */
/**
 *  初始化方法
 *
 *  @param sessonDic sessionDic 拉流需要的参数（字典）
 *  @param view 拉流时候的预览view
 *
 *  @return StreamBasedQiNiu 封装后的拉流类
 */

-(instancetype)initWithSessionJsonDic:(NSDictionary*)sessionDic Inview:(UIView*)view;

#pragma mark StreamRelate
/**
 *  开始推流
 */
- (void)startStreamWithFeedback:(void (^)(BOOL))startStreamCallback;
- (void)startStream ;
/**
 *  快速重新开始推流（处于正在推流过程中，由于业务原因（如用户网络从 4G 切到 WIFI）需要快速重新推流时，可以调用此方法重新推流）
 */
- (void)restartStream;
/**
 *  结束推流
 */
- (void)stopStream;
/**
 *  摄像头方向
 */
- (void)toggleCameraStream;
/**
 *  摧毁流
 */
- (void)destorySteam;

/**
 *  reloadCofig,,test
 */
- (void)reloadCofig;


@end
