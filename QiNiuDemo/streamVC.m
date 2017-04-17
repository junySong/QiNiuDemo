//
//  streamVC.m
//  QiNiuDemo
//
//  Created by 宋俊红 on 16/8/18.
//  Copyright © 2016年 Juny_song. All rights reserved.
//


#import "streamVC.h"

@interface streamVC ()


@property (nonatomic, strong) UIButton *button;
@property (nonatomic, assign) BOOL isruning;//是否正在推流

@end

@implementation streamVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self buildButton];
    if (self.streamJsonDic) {
        _streamQiNiu  = [[StreamBasedQiNiu alloc]initWithSessionJsonDic:self.streamJsonDic Inview:self.view];
       
        if ([_streamQiNiu respondsToSelector:@selector(startStream)]) {
            NSLog(@"fsdfsdfsdfsd");
             [_streamQiNiu startStreamWithFeedback:^(BOOL is) {
                 
             }];
        }else{
            NSLog(@"-----------------");
        }
         [_button setTitle:@"结束推流" forState:UIControlStateNormal];
        self.isruning = YES;
    }
    
    
//    [self performSelector:@selector(reloadConfig) withObject:nil afterDelay:30];
    
//    [self.streamQiNiu startStream];

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
- (void)buildButton{
    if (!_button) {
        CGFloat screen_width  = [UIScreen mainScreen].bounds.size.width;
        CGFloat screen_height  = [UIScreen mainScreen].bounds.size.height;
        _button = [[UIButton alloc]initWithFrame:CGRectMake(100,screen_height-100 , 100, 40)];
        _button.backgroundColor = [UIColor blueColor];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
         [_button setTitle:@"结束推流" forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(btnCilck) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_button];
    }
}

- (void)setButtonTitle{
    NSLog(@"self.streamQiNiu.session.streamState---%ld",self.streamQiNiu.session.streamState);
    if (_isruning) {
        [_button setTitle:@"结束推流" forState:UIControlStateNormal];
    }else{
        [_button setTitle:@"开始推流" forState:UIControlStateNormal];
    }
}

- (void)setStreamState{
    
     NSLog(@"self.streamQiNiu.session.streamState---%ld",self.streamQiNiu.session.streamState);
    if (_isruning) {
        [self.streamQiNiu stopStream];
    }else{
        [self.streamQiNiu restartStream];
    }
}
- (void)btnCilck{
    [self setStreamState];
    self.isruning = !self.isruning;
    [self setButtonTitle];
    
    
}
- (void)prepareVedio{
   
}

- (void)reloadConfig{
      NSLog(@"------reloadCofig---");
    [self.streamQiNiu reloadCofig];
}
@end
