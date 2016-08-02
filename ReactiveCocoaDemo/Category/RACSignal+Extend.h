//
//  RACSignal+Extend.h
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (Extend)

- (RACSignal *)serialCollect:(RACSignal *)signal;

@end
