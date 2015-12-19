//
//  ViewController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/8/22.
//  Copyright (c) 2015年 zd. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "ZDAFNetWorkHelper.h"


#define FORMATSTRING(FORMAT, ...) ([NSString stringWithFormat:FORMAT, ##__VA_ARGS__])

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self signal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)signal
{
    //[self zip];
    
    //[self skip];
    
    //[self take];
    
    //[self concat];
    
    //[self replay];
    [self replay1];
    //[self replayLazily];
    
    //[self deliverOn];
    
}

#pragma mark - Signal
#pragma mark -

/**
 *  @author 符现超, 15-08-23 23:08:29
 *
 *  @brief  压缩: 把两个信号中的数据连到一起，生成一个RACTuple，比如下面的demo，如果打开signalB中的sendNext:@"4", 则会输出2次，输出结果分别为13，24，如果不打开则只输出一个结果：13，相当于两个信号中的数据会一一映射，当对应的数据缺失时则不执行压缩操作
 *
 *  [C zipWith:D]可以比喻成一对平等恩爱的夫妻，两个人是“绑在一起“的关系来组成一个家庭，决定一件事（value）时必须两个人都提出意见（当且仅当C和D同时都产生了值的时候，一个value才被输出，C、D只有其中一个有值时会挂起等待另一个的值，所以输出都是一对值（RACTuple）），当夫妻只要一个人先挂了（completed）这个家庭（组合起来的RACStream）就宣布解散（也就是无法凑成一对输出时就终止）
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
 *  @brief  合并拼接：把一个信号传递的数据拼接到另一个信号的数据上
 *
 *  [A concat:B]中A和B像皇上和太子的关系，A是皇上，B是太子。皇上健在的时候统治天下发号施令（value），太子就候着，不发号施令（value），当皇上挂了（completed），太子登基当皇上，此时发出的号令（value）是太子的。
 *  
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
 *  replayLazily 不会重新执行,他与其他2个不同之处是RAC中的信号只有在被订阅后才会执行，而其他的只要执行到那就会执行，就跟do-while一样
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

- (void)replay1
{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"hello"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            //
        }];
    }] replay];
    
    [[signal map:^id(NSString *value) {
        return @(value.length);
    }] subscribeNext:^(id x) {
        NSLog(@"1 == %@", x);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"2 == %@", x);
    }];
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

/**
 *  可以切换调用的线程
 */
- (void)deliverOn
{
    
}

//http://blog.sunnyxx.com/2014/04/19/rac_4_filters/
/**
 *  忽略给定的值，注意，这里忽略的既可以是地址相同的对象，也可以是- isEqual:结果相同的值，也就是说自己写的Model对象可以通过重写- isEqual:方法来使- ignore:生效。
 */
- (void)ignore
{
    
}

/**
 *  也是一个相当常用的Filter（但它不是- filter:的衍生方法），它将这一次的值与上一次做比较，当相同时（也包括- isEqual:）被忽略掉。
 */
- (void)distinctUntilChanged
{
    
}

/**
 *  这个比较极端，忽略所有值，只关心Signal结束，也就是只取Comletion和Error两个消息，中间所有值都丢弃。
 注意，这个操作应该出现在Signal有终止条件的的情况下，如rac_textSignal这样除dealloc外没有终止条件的Signal上就不太可能用到。
 */
- (void)ignoreValues
{
    
}


/**
 *  @author 符现超, 15-08-23 23:08:45
 *
 *  @brief  跳过：它会把第三条数据之前的所有数据都跳过，然后只输出第四条极其后面的数据，下面的输出结果为4，5（一次输出一条数据）
 *
 *
 *  - skipUntilBlock:(BOOL (^)(id x))
 
 和- takeUntilBlock:同理，一直跳，直到block为YES
 
 - skipWhileBlock:(BOOL (^)(id x))
 
 和- takeWhileBlock:同理，一直跳，直到block为NO
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
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            //
        }];
    }];
    
    [[signal take:3] subscribeNext:^(id x) {
        NSLog(@"%@", x);
        NSLog(@"only “你好、1、 2” will be print: %@", x);
    }];
}

/**
 *  - takeLast: (NSUInteger)
 
 取最后N次的next值，注意，由于一开始不能知道这个Signal将有多少个next值，所以RAC实现它的方法是将所有next值都存起来，然后原Signal完成时再将后N个依次发送给接收者，但Error发生时依然是立刻发送的。
 
 
 - takeUntil:(RACSignal *)
 
 当给定的signal完成前一直取值。最简单的栗子就是UITextField的rac_textSignal的实现（删减版本）:
 
 - (RACSignal *)rac_textSignal {
	@weakify(self);
	return [[[[[RACSignal
 concat:[self rac_signalForControlEvents:UIControlEventEditingChanged]]
 map:^(UITextField *x) {
 return x.text;
 }]
 takeUntil:self.rac_willDeallocSignal] // bingo!
 }

 也就是这个Signal一直到textField执行dealloc时才停止
 
 
 ###- takeUntilBlock:(BOOL (^)(id x))
 对于每个next值，运行block，当block返回YES时停止取值，如：
 
 [[self.inputTextField.rac_textSignal takeUntilBlock:^BOOL(NSString *value) {
 return [value isEqualToString:@"stop"];
 }] subscribeNext:^(NSString *value) {
 NSLog(@"current value is not `stop`: %@", value);
 }];
 
 
 - takeWhileBlock:(BOOL (^)(id x))
 
 上面的反向逻辑，对于每个next值，block返回 YES时才取值
 

 */

- (void)timer
{
    ///常用两种：
    //1. 延迟某个时间后再做某件事
    [[RACScheduler mainThreadScheduler] afterDelay:2 schedule:^{
        
        NSLog(@"你好");
    }];
    
    //2. 每个一定长度时间做一件事
    [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate * date) {
        
        NSLog(@"你好啊");
    }];
}




@end




