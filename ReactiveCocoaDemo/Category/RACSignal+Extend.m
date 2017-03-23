//
//  RACSignal+Extend.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import "RACSignal+Extend.h"

static double lastTime = 0;
@interface RACSignal ()
@end

@implementation RACSignal (Extend)

- (RACSignal *)serialCollect:(NSArray<RACSignal *> *)signals {
    NSParameterAssert(signals);
    NSMutableArray *signalsArr = ({
        NSMutableArray *mutArr = @[].mutableCopy;
        [mutArr addObject:self];
        [mutArr addObjectsFromArray:signals];
        mutArr;
    });
    return [[[RACSignal concat:signalsArr] collect] setNameWithFormat:@"[%@] -serialCollect: %@", self.name, signals];
}

- (RACSignal *)filterEventWithInterval:(NSTimeInterval)interval {
    //RACSignal *hotSignal = [self replayLast];
    //[[self take:1] concat:[self skip:1]];
    return [[self filter:^BOOL(id value) {
        double currentTime = CFAbsoluteTimeGetCurrent();
        if (lastTime > 0 && currentTime - lastTime > interval) {
            lastTime = CFAbsoluteTimeGetCurrent();
            return YES;
        }
        else {
            lastTime = currentTime;
            return NO;
        }
    }] setNameWithFormat:@"[%@] -filterEventWithInterval: %@", self.name, self];
}

@end
