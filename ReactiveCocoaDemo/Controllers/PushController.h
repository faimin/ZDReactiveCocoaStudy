//
//  PushController.h
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 15/12/24.
//  Copyright © 2015年 zd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

static NSString *const kNotification = @"notification";

@interface PushController : UIViewController
@property (nonatomic, strong) RACCommand *command;
@end
