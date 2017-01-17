//
//  RACSignal+Extend.h
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (Extend)

/// 连接多个请求后把结果放在一起
- (RACSignal *)serialCollect:(NSArray<RACSignal *> *)signals;

/// 防止按钮被连续点击
- (RACSignal *)filterEvent:(NSTimeInterval)interval;

@end
