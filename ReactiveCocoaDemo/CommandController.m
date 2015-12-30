//
//  CommandController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/12/23.
//  Copyright © 2015年 zd. All rights reserved.
//

#import "CommandController.h"
#import <LxDBAnything.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ZDAFNetWorkHelper.h"


@interface CommandController ()

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation CommandController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self postNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)postNotification
{
    __block NSUInteger i = 0;
    [[self.sendButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification" object:@(++i)];
    }];
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
