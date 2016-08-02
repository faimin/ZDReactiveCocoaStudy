//
//  RACSignal+Extend.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import "RACSignal+Extend.h"

@implementation RACSignal (Extend)

- (RACSignal *)serialCollect:(RACSignal *)signal {
    return [[self concat:signal] collect];
}

@end
