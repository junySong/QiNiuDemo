//
//  ViewController.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/10.
//  Copyright © 2016年 Juny_song. All rights reserved.
//

#import "ViewController.h"
#import "JSSteamViewController.h"
#import "JSPlayerViewController.h"
#import "PlayVC.h"
#import "streamVC.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"录入" forState:UIControlStateNormal];
    button.frame = CGRectMake(0,100, 100, 44);
//    button.center = self.view.center;
    [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.backgroundColor = [UIColor blueColor];
    [button1 setTitle:@"播放" forState:UIControlStateNormal];
    button1.frame = CGRectMake(0, 200, 100, 44);
    [button1 addTarget:self action:@selector(actionbutton1Pressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];

    
    NSUInteger i=1;
    NSUInteger j=i-1;
    NSLog(@"%lu,---%lu",(unsigned long)i,(unsigned long)j);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark ------liftCycle--------

#pragma mark ----action---

- (void)actionButtonPressed:(UIButton*)sender{
//    JSSteamViewController *vc = [[JSSteamViewController alloc]init];
//    [self presentViewController:vc animated:YES completion:^{
//        
//    }];
    NSString *jsonstring = @"{\"id\":\"z1.newlive.Juny\",\"createdAt\":\"2016-08-15T11:02:03.038+08:00\",\"updatedAt\":\"2016-08-15T11:02:03.038+08:00\",\"title\":\"Juny\",\"hub\":\"newlive\",\"disabledTill\":0,\"disabled\":false,\"publishKey\":\"a7b7642cdd38fb2e\",\"publishSecurity\":\"dynamic\",\"hosts\":{\"publish\":{\"rtmp\":\"pili-publish.newzhibo.cn\"},\"live\":{\"hdl\":\"pili-live-hdl.newzhibo.cn\",\"hls\":\"pili-live-hls.newzhibo.cn\",\"http\":\"pili-live-hls.newzhibo.cn\",\"rtmp\":\"pili-live-rtmp.newzhibo.cn\",\"snapshot\":\"pili-live-snapshot.newzhibo.cn\"},\"playback\":{\"hls\":\"10002b9.playback1.z1.pili.qiniucdn.com\",\"http\":\"10002b9.playback1.z1.pili.qiniucdn.com\"},\"play\":{\"http\":\"pili-live-hls.newzhibo.cn\",\"rtmp\":\"pili-live-rtmp.newzhibo.cn\"}}}";
    
    NSError *error;
    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:[jsonstring dataUsingEncoding:NSUTF8StringEncoding]options:NSJSONReadingMutableContainers error:&error];
    streamVC *vc = [[streamVC alloc]init];
    vc.streamJsonDic = responseDic;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}
- (void)actionbutton1Pressed:(UIButton*)sender{
//     JSPlayerViewController *vc = [[JSPlayerViewController alloc]init];
//    vc.URL = [NSURL URLWithString:@"rtmp://pili-live-rtmp.newzhibo.cn/newlive/Juny"];
//    
//    [self presentViewController:vc animated:YES completion:^{
//        
//    }];
    
    PlayVC *vc = [[PlayVC alloc]init];
    //rtmp://pili-live-rtmp.newzhibo.cn/newlive/Juny
    //record/live/86542/hls/86542-4788859207806594404.m3u8
    vc.URL = [NSURL URLWithString:@"record/live/86542/hls/86542-4788859207806594404.m3u8"];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
    
}


@end
