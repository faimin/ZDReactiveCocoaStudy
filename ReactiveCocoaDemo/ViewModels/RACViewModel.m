//
//  RACViewModel.m
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 2018/9/17.
//  Copyright © 2018年 zd. All rights reserved.
//

#import "RACViewModel.h"

@implementation RACViewModel

- (void)foo:(id)value1 :(id)value2 {
    NSLog(@"%s, value1 = %@, value2 = %@", __PRETTY_FUNCTION__, value1, value2);
}

@end
