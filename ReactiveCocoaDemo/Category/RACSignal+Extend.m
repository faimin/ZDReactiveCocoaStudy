//
//  RACSignal+Extend.m
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 16/8/2.
//  Copyright © 2016年 zd. All rights reserved.
//  
//  http://www.enhgo.com/search?q=RACSignal

#import "RACSignal+Extend.h"

@implementation RACSignal (Extend)

- (RACSignal *)serialCollect:(NSArray<RACSignal *> *)signals {
    NSCParameterAssert(signals.count);
    if (!signals.count) return self;
    
    NSMutableArray *signalsArr = ({
        NSMutableArray<RACSignal *> *mutArr = @[].mutableCopy;
        [mutArr addObject:self];
        [mutArr addObjectsFromArray:signals];
        mutArr;
    });
    return [[[RACSignal concat:signalsArr] collect] setNameWithFormat:@"[%@] -serialCollect: %@", self.name, signals];
}

- (RACSignal *)filterEventWithInterval:(NSTimeInterval)interval {
    //RACSignal *hotSignal = [self replayLast];
    //[[self take:1] concat:[self skip:1]];
    static double lastTime = 0.0;
    
    return [[self filter:^BOOL(id value) {
        double currentTime = CFAbsoluteTimeGetCurrent();
        if ( lastTime == 0 || (lastTime > 0 && currentTime - lastTime >= interval) ) {
            lastTime = CFAbsoluteTimeGetCurrent();
            return YES;
        }
        else {
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

// http://www.enhgo.com/snippet/objective-c/racsignalcontinueinbackgroundm_neilpa_objective-c
- (RACSignal *)continueInBackground
{
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        UIApplication *app = UIApplication.sharedApplication;
        
        __block UIBackgroundTaskIdentifier taskID;
        RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
        RACDisposable *backgroundTaskDisposable = [RACDisposable disposableWithBlock:^{
            [app endBackgroundTask:taskID];
        }];
        
        // To ensure the background task isn't ended before the error or completed event
        // is delivered we have to remove the background disposable from our compound
        // disposable. Otherwise, the internal signal executes the disposable before actually
        // invoking the error or completion blocks. As such, we have to do this dance with
        // the background disposable.
        
        taskID = [app beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background task timed out.");
            [compoundDisposable removeDisposable:backgroundTaskDisposable];
            [subscriber sendError:[NSError errorWithDomain:RACSignalErrorDomain code:RACSignalErrorTimedOut userInfo:nil]];
            [backgroundTaskDisposable dispose];
        }];
        
        RACDisposable *subscriptionDisposable = [self subscribeNext:^(id x) {
            [subscriber sendNext:x];
        } error:^(NSError *error) {
            [compoundDisposable removeDisposable:backgroundTaskDisposable];
            [subscriber sendError:error];
            [backgroundTaskDisposable dispose];
        } completed:^{
            [compoundDisposable removeDisposable:backgroundTaskDisposable];
            [subscriber sendCompleted];
            [backgroundTaskDisposable dispose];
        }];
        
        // Add the background disposable last since it should run after the subscription
        // is cleaned up.
        [compoundDisposable addDisposable:subscriptionDisposable];
        [compoundDisposable addDisposable:backgroundTaskDisposable];
        return compoundDisposable;
    }]
    setNameWithFormat:@"[%@] -continueInBackground", self.name];
}

@end
