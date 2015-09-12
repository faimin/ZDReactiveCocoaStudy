//
//  ViewController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/8/22.
//  Copyright (c) 2015年 zd. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "ZAFNetWorkService.h"


#define FORMATSTRING(FORMAT, ...) ([NSString stringWithFormat:FORMAT, ##__VA_ARGS__])

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self test];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Test

- (void)test
{
    //[self zip];
    
    //[self skip];
    
    //[self take];
    
    //[self concat];
    
    //[self replay];
    
    [self replayLazily];
    
}

/**
 *  @author 符现超, 15-08-23 23:08:29
 *
 *  @brief  压缩: 把两个信号中的数据连到一起，生成一个RACTuple，比如下面的demo，如果打开signalB中的sendNext:@"4", 则会输出2次，输出结果分别为13，24，如果不打开则只输出一个结果：13，相当于两个信号中的数据会一一映射，当对应的数据缺失时则不执行压缩操作
 */
- (void)zip
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"3"];
        //[subscriber sendNext:@"4"];
        return nil;
    }];
    
    [[signalA zipWith:signalB] subscribeNext:^(id x) {
        RACTupleUnpack(NSString *str1, NSString *str2) = x;
        NSString *str = FORMATSTRING(@"%@%@", str1, str2);
        NSLog(@"%@,\n %@", x, str);
    }];
}

/**
 *  @author 符现超, 15-08-23 23:08:45
 *
 *  @brief  跳过：它会把第三条数据之前的所有数据都跳过，然后只输出第四条极其后面的数据，下面的输出结果为4，5（一次输出一条数据）
 */
- (void)skip
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@13];
        [subscriber sendNext:@4];
        [subscriber sendNext:@2];
        return nil;
    }];
    
    [[signalA skip:3] subscribeNext:^(id x) {
        NSLog(@"skip result = %@", x);
    }];
    
    ///当某一个数据符合block里面的条件时就会把它之前的数据都跳过去了，只输出后面的数据，此时block也不再执行
    [[signalA skipUntilBlock:^BOOL(id x) {
        if ([x integerValue] > 2)
        {
            return YES;
        }
        return NO;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/**
 *  take与skip相反，它是取take的前几条数据
 */
- (void)take
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"你好"];
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@13];
        [subscriber sendNext:@4];
        [subscriber sendNext:@2];
        return nil;
    }];
    
    [[signal take:3] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/**
 *  拼接：把一个信号传递的数据拼接到另一个信号的数据上
 *  下面的返回结果是ABCDEFGHI123456789
 */

- (void)concat
{
    RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    
    RACSequence *concat = [letters concat:numbers];
    NSLog(@"%@", [concat array]);
}

/**
 *  重新运行：当有新的订阅者时信号会重新发送以前发送过的数据给这个订阅者
 *  下面的例子中，如果不加replay，则第二个订阅者不会受到它上面已经发送过的信号（即s2不执行，不打印任何数据），加上replay后它会收以前已经发送过的A和B两个数据。
 *  replayLast会把最后一个信号数据发给后来的订阅者，如下，s2只会输出B
 *  replayLazily 不会重新执行
 *  http://spin.atomicobject.com/2014/06/29/replay-replaylast-replaylazily/
 */
- (void)replay
{
    RACSubject *letters = [RACSubject subject]; //RACSubject是RACSignal的子类，它可以快速创建一个信号，用来发送信息
    //RACSignal *signal = [letters replay];
    //RACSignal *signal = [letters replayLast];
    RACSignal *signal = [letters replayLazily];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"S1:   %@", x);
    }];
    
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"S2:   %@", x);
    }];
    
//        [letters sendNext:@"C"];
//        [letters sendNext:@"D"];
    
//    [signal subscribeNext:^(id x) {
//        NSLog(@"S3:   %@", x);
//    }];
}

/**
 *  replay或者replayLazily只会让信号里面只发送一次，即只执一次num++，当有订阅者时就只会拿到信号当初发送的数据，不会重新发送新的，如果不用replay，则每次有订阅者都会导致racsignal执行一次
 */
- (void)replayLazily
{
    __block int num = 0;
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id  subscriber) {
        num++;
        NSLog(@"Increment num to: %i", num);
        [subscriber sendNext:@(num)];
        return nil;
    }] replayLazily];
    
    
    [signal subscribeNext:^(id x) {
        NSLog(@"S1: %@", x);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"S2: %@", x);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"S3: %@", x);
    }];
}

@end




