//
//  PlayerBasedQINiu.h
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/16.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLPlayerKit/PLPlayerKit.h>
#import "Reachability.h"
@class PlayerBasedQINiu;
@protocol PlayerBasedQINiuDelegate <NSObject>

@optional
/**
 告知代理对象播放器状态变更
 
 @param player 调用该方法的 PLPlayer 对象
 @param state  变更之后的 PLPlayer 状态
 
 @since v1.0.0
 */
//NS_ASSUME_NONNULL_BEGIN NS_ASSUME_NONNULL_END
- (void)playerOfQiNiu:( PlayerBasedQINiu *)qiNiuPlayer statusDidChange:(PLPlayerStatus)state;
/**
 告知代理对象播放器因错误停止播放
 
 @param player 调用该方法的 PLPlayer 对象
 @param error  携带播放器停止播放错误信息的 NSError 对象
 
 @since v1.0.0
 */

- (void)playerOfQiNiu:( PlayerBasedQINiu *)qiNiuPlayer stoppedWithError:( NSError *)error;

@end



@interface PlayerBasedQINiu : NSObject

@property (nonatomic, assign ) NSInteger reconnectCount;//
@property (nonatomic, strong ) NSURL *URL;
@property (nonatomic, strong ) PLPlayer *player;
@property (nonatomic, strong) Reachability *internetReachability;//监控网络状态
/**
 代理对象，用于告知播放器状态改变或其他行为，对象需实现 PlayerBasedQINiuDelegate 协议
 
 @since v1.0.0
 */
@property (nonatomic, weak) id<PlayerBasedQINiuDelegate>  delegate;

- (void)prepareForVideoInView:(UIView *)view;
#pragma mark -----action------
/**
 *  播放或者是暂停，当前状态是播放状态，此操作是暂停操作；当前状态是暂停状态，此操作是播放操作
 */
- (void)playAction;
/**
 *  停止操作
 */
- (void)stopAction;
/**
 *  暂停操作
 */
- (void)pauseAction;
/**
 *  暂停状态下的的播放操作
 */
- (void)resumeAction;
/**
 *  视频总时长无符号整型，仅回放状态下有效果,只播放状态下将返回nil
 */
- (NSUInteger)totalTime;
/**
 *  根据进度条，跳转到指定时间
 *
 *  @param currentTime 0.0~1.0之间，超出区间或者是只播放状态下，不做处理；
 */
- (void)seekToTime:(CGFloat)currentTime;
@end

