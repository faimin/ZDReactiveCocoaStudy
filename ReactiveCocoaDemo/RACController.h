//
//  ViewController.h
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 15/8/22.
//  Copyright (c) 2015年 zd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RACController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (nonatomic, assign) NSUInteger type;
@end
