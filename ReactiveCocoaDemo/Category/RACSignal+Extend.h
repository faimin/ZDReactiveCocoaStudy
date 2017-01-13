//
//  RACSignal+Extend.h
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (Extend)

/// 连接2个请求后把结果放在一起
- (RACSignal *)serialCollect:(RACSignal *)signal;

/// 防止按钮多次点击
- (RACSignal *)filterEvent:(NSTimeInterval)interval;

@end
