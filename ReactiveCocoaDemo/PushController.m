//
//  PushController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/12/24.
//  Copyright © 2015年 zd. All rights reserved.
//

#import "PushController.h"
#import <LxDBAnything.h>


@interface PushController ()
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@end

@implementation PushController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self notification];
    
    self.okButton.rac_command = self.command;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)notification
{
    /**
     *  必须要添加takeUntil来控制release信号，否则会出现内存泄露
     */
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:kNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *x) {
        LxDBAnyVar(x.object);
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








