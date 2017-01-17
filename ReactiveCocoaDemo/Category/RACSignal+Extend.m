//
//  RACSignal+Extend.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//

#import "RACSignal+Extend.h"

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

- (RACSignal *)filterEvent:(NSTimeInterval)interval {
    RACSignal *hotSignal = [self replayLast];
    __block double lastTime = 0;
    return [[[hotSignal take:1] concat:[[hotSignal skip:1] filter:^BOOL(id value) {
        double currentTime = CFAbsoluteTimeGetCurrent();
        if (lastTime > 0 && currentTime - lastTime > interval) {
            lastTime = CFAbsoluteTimeGetCurrent();
            return YES;
        }
        return NO;
    }]] setNameWithFormat:@"[%@] -filterEvent: %@", self.name, self];
}

@end
