//
//  RACSignal+Extend.m
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 16/8/2.
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

// https://gist.github.com/jaredru/5540a15c5a1bdcc31787
- (RACSignal *)shareWhileActive {
    NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
    lock.name = @"com.github.ReactiveCocoa.shareWhileActive";
    
    // These should only be used while `lock` is held.
    __block NSUInteger subscriberCount = 0;
    __block RACDisposable *underlyingDisposable = nil;
    __block RACReplaySubject *inflightSubscription = nil;
    
    return [[RACSignal
             createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                 __block RACSignal*     signal     = nil;
                 __block RACDisposable* disposable = nil;
                 
                 [lock lock];
                 @onExit {
                     [lock unlock];
                     disposable = [signal subscribe:subscriber];
                 };
                 
                 if (subscriberCount++ == 0) {
                     // We're the first subscriber, so create the underlying
                     // subscription.
                     inflightSubscription = [RACReplaySubject subject];
                     underlyingDisposable = [self subscribe:inflightSubscription];
                 }
                 
                 signal = inflightSubscription;
                 
                 return [RACDisposable disposableWithBlock:^{
                     [disposable dispose];
                     
                     [lock lock];
                     @onExit {
                         [lock unlock];
                     };
                     
                     NSCAssert(subscriberCount > 0, @"Mismatched decrement of subscriberCount (%lu)", (unsigned long)subscriberCount);
                     if (--subscriberCount == 0) {
                         // We're the last subscriber, so dispose of the
                         // underlying subscription.
                         [underlyingDisposable dispose];
                         underlyingDisposable = nil;
                         
                         // Also, release the inflightSubscription, since
                         // we won't need its stored values any longer.
                         inflightSubscription = nil;
                     }
                 }];
             }]
            setNameWithFormat:@"[%@] -shareWhileActive", self.name];
}

@end
