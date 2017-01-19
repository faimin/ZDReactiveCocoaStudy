//
//  ViewController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/8/22.
//  Copyright (c) 2015年 zd. All rights reserved.
//  信号演示网站：http://rxmarbles.com/    http://neilpa.me/rac-marbles/
//  Reactive Cocoa 学习笔记：http://www.tuicool.com/articles/Yrim6zZ


#import "RACController.h"
#import "PushController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ZDAFNetWorkHelper.h"

#define FORMATSTRING(FORMAT, ...)                   \
  ([NSString stringWithFormat:FORMAT, ##__VA_ARGS__])

#define MovieAPI    @"http://api.douban.com/v2/movie/top250"
#define WeatherAPI  @"http://www.weather.com.cn/data/cityinfo/101010100.html"

@interface RACController ()

@property(weak, nonatomic) IBOutlet UITextField *textField;
@property(weak, nonatomic) IBOutlet UIButton *showTextButton;
@property(weak, nonatomic) IBOutlet UIButton *pushButton;
@property (nonatomic, copy) NSString *tempText;

@end

@implementation RACController

- (void)dealloc {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self signals];
    //[self actions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Signal
#pragma mark -

- (void)signals
{
    switch (self.type) {
        case 0:
            [self bind];
            break;
        case 1:
            [self flattenMap];
            break;
        case 2:
            [self flatten];
            break;
        case 3:
            [self map];
            break;
        case 4:
            [self zip];
            break;
        case 5:
            [self merge];
            break;
        case 6:
            [self combineLatestReduce];
            break;
        case 7:
            [self concat];
            break;
        case 8:
            [self then];
            break;
        case 9:
            [self replay1];
            break;
        case 10:
            [self replayLazily];
            break;
        case 11:
            [self mutableConnection];
            break;
        case 12:
            [self deliverOn];
            break;
        case 13:
            [self distinctUntilChanged];
            break;
        case 14:
            [self throttle];
            break;
        case 15:
            [self ignore];
            break;
        case 16:
            [self ignoreValues];
            break;
        case 17:
            [self skip];
            break;
        case 18:
            [self take];
            break;
        case 19:
            [self takeUntil];
            break;
        case 20:
            [self timer];
            break;
        case 21:
            [self swithToLatest];
            break;
        case 22:
            [self materialize];
            break;
        case 23:
            [self liftSelector];
            break;
        case 24:
            [self collect];
            break;
        case 25:
            [self scanWithStart];
            break;
        case 26:
            [self combinePreviousWithStart];
            break;
        case 27:
            [self aggregate];
            break;
        case 28:
            [self bufferWithTime];
            break;
        case 29:
            [self channel];
            break;
        case 30:
            [self reduceApply];
            break;
        case 31:
            [self sequence];
            break;
        default:
            break;
    }
}

#pragma mark - Functions
#pragma mark -
// RACSignal底层实现：
// 1.创建信号，首先把didSubscribe保存到信号中，还不会触发。
// 2.当信号被订阅，也就是调用signal的subscribeNext:nextBlock
// 2.1 subscribeNext内部会创建订阅者subscriber，并且把nextBlock保存到subscriber中。
// 2.2 subscribeNext内部会调用siganl的didSubscribe
// 3.siganl的didSubscribe中调用[subscriber sendNext:@1];
// 3.1 sendNext底层其实就是执行subscriber的nextBlock


- (void)bind
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"2017年01月17日15:38:04"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"bind信号释放了");
        }];
    }];
    
    RACSignal *signalB = [signalA bind:^RACStreamBindBlock{
        // 下面这个block的回调时机是：
        // 下面的bindBlock是在signalA的subscribeNext的block中回调的，所以当signalA被订阅且signalA发送值后，bindBlock会发生回调，然后回调的第一个参数是signalA发送过来的值，也就是说下面bindBlock中参数value的值即为 @"2017年01月17日15:38:04"
        RACStream *(^BindBlock) (id value, BOOL *stop) = ^RACStream * (id value, BOOL *stop) {
            NSString *componentString = [NSString stringWithFormat:@"%@, 哈咪", value];
            RACSignal *signal = [RACSignal return:componentString];
            return signal;
        };
        return BindBlock;
    }];
    
    [signalB subscribeNext:^(id x) {
        NSLog(@"执行bind之后的结果：%@", x);
    }];
}

- (void)flattenMap
{
    RACSignal *signal = [RACSignal return:@"你好"];
    
    [[signal flattenMap:^RACStream *(NSString *value) {
        RACSignal *innerSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:[value stringByAppendingString:@",我是内部信号中的值"]];
            return nil;
        }];
        return innerSignal;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

- (void)flatten
{
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"测试flatten函数"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signal2 = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:signal1];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"dispose");
        }];
    }] replay];
    
    [[signal2 map:^id(id value) {
        NSLog(@"%@", value); // 最终变为中间信号
        return value;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [[signal2 flatten] subscribeNext:^(id x) {
        NSLog(@"%@", x);   
    }];
}

- (void)map
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"map1"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"释放了");
        }];
    }];
    
    // sendNext后会执行订阅block
    [[signal map:^id(id value) {
        NSString *newString = FORMATSTRING(@"%@, hello world!", value);
        NSLog(@"%@", newString);
        return value;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

///  把多个信号合并成一个信号，任何一个信号有新值的时候就会调用，它会按照时间的先后顺序把信号排列起来
///  和combine reduce差不多,总是返回最新的信号，
///  区别：每次merge返回的是单一的信号，不能组合，而combineLatest可以把最新返回的信号跟另一个信号进行组合，另一个信号是它的上次的那个信号。可以简单理解成combineLatest可以组合，而merge却不行
- (void)merge
{
    // 看源码可知，merge是把几个信号顺序放入到一个数组中，然后放入一个新的信号中，当这个新的信号被订阅时，数组中的信号会被订阅者依次订阅，由于这是信号中的信号，所以最后做了依次flatten操作，取出其中的值。
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"3"];
        [subscriber sendNext:@"4"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    // 依次print 1，2，3，4
    [[RACSignal merge:@[signalA, signalB]] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
//    or:
//    [[signalA merge:signalB] subscribeNext:^(NSString *x) {
//        NSLog(@"%@", x);
//    }];
}

/// 将一组Signal发出的最新的事件合并成一个Signal，每当这组Signal发出新事件时，reduce的block会执行，将所有新事件的值合并成一个值，并当做合并后Signal的事件发出去。
/// 这个方法会返回合并后的Signal。
/// reduce的block中参数，其实是与combineLatest中数组元素一一对应的
- (void)combineLatestReduce
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendNext:@"3"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"11"];
        [subscriber sendNext:@"12"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalC = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"21"];
        [subscriber sendNext:@"22"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[RACSignal combineLatest:@[signalA, signalB, signalC] reduce:^id(NSString *a , NSString *b, NSString *c){
        NSString *resultString = [NSString stringWithFormat:@"\na = %@, b = %@, c = %@", a, b, c];
        NSLog(@"%@", resultString);
        return resultString;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [[RACSignal combineLatest:@[signalA, signalB]] subscribeNext:^(RACTuple *x) {
        RACSequence *seque = x.rac_sequence;
        NSArray *resultArray = seque.array;
        NSLog(@"%@", resultArray);
        
        RACTupleUnpack(NSString *str1, NSString *str2) = x;
        NSString *str = FORMATSTRING(@"%@%@", str1, str2);
        NSLog(@"%@,\n %@", x, str);
    }];
}

///  @brief  压缩: 把两个信号中的数据连到一起，生成一个RACTuple，[A
/// zipWith:B]中A和B至少发送过一次消息，zip才会把他们打包成一个tuple
///
///  比如下面的demo，如果打开signalB中的sendNext:@"4",
///  则会输出2次，输出结果分别为13，24，如果不打开则只输出一个结果：13，相当于两个信号中的数据会一一映射，当对应的数据缺失时则不执行压缩操作
///
///  意味着如果是一个流的第N个元素，一定要等到另外一个流第N值也收到才会一起组合发出。
///
///  [C zipWith:D]可以比喻成一对平等恩爱的夫妻，两个人是“绑在一起“的关系来组成一个家庭，决定一件事（value）时必须两个人都提出意见（当且仅当C和D同时都产生了值的时候，一个value才被输出，C、D只有其中一个有值时会挂起，等待另一个的值，所以输出都是一对值（RACTuple）），当夫妻只要一个人先挂了（completed）这个家庭（组合起来的RACStream）就宣布解散（也就是无法凑成一对输出时就终止）
- (void)zip
{
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"3"];
        //[subscriber sendNext:@"4"];
        return nil;
    }];
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
           NSLog(@"取消订阅signalA");
        }];
    }];

    [[signalB zipWith:signalA] subscribeNext:^(id x) {
        RACTupleUnpack(NSString *str1, NSString *str2) = x;
        NSString *str = FORMATSTRING(@"%@%@", str1, str2);
        NSLog(@"%@,\n %@", x, str);
    }];
}

/// @brief  连接
/// 把一个信号传递的数据拼接到另一个信号的数据后面
/// 返回一个新的数组，该数组是通过把所有 arrayX 参数添加到 arrayObject 中生成的。如果要进行 concat() 操作的参数是数组，那么添加的是数组中的元素，而不是数组。
///
/// [A concat:B]中只有A信号执行完complete之后才会执行B，如果A失败（比如执行了sendError），则B永远不会执行
///
/// A和B像皇上和太子的关系，A是皇上，B是太子。皇上健在的时候统治天下发号施令（value），太子就候着，不发号施令（value），当皇上挂了（completed），太子登基当皇上，此时发出的号令（value）是太子的。
- (void)concat
{
    RACSequence *letters =
      [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers =
      [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;

    RACSequence *concat = [letters concat:numbers];
    NSLog(@"%@", [concat array]);
    //print: ABCDEFGHI123456789
}

/// 当一个订阅者被发送了completed事件后，then:方法才会执行，订阅者会订阅then:方法返回的Signal，这个Signal是在block中返回的。（忽略掉第一个信号的所有值）
/// 这样优雅的实现了从一个Signal到另一个Signal的订阅。
- (void)then
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendNext:@"3"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"11"];
        [subscriber sendNext:@"12"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[signalA then:^RACSignal *{
        return signalB;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// 重新运行：当有新的订阅者时信号会重新发送以前发送过的数据给这个订阅者
/// 下面的例子中，如果不加replay，则第二个订阅者不会受到它上面已经发送过的信号（即s2不执行，不打印任何数据），加上replay后它会收以前已经发送过的A和B两个数据。
/// replayLast会把最后一个信号数据发给后来的订阅者，如下，s2只会输出B
/// replayLazily
/// 不会重新执行,他与其他2个不同之处是RAC中的信号只有在被订阅后才会执行，而其他的只要执行到那就会执行，就跟do-while一样
/// http://spin.atomicobject.com/2014/06/29/replay-replaylast-replaylazily/
- (void)replay
{
    ///// RACSubject是RACSignal的子类，它可以快速创建一个信号，用来发送信息
    RACSubject *letters = [RACSubject
          subject];
    // RACSignal *signal = [letters replay];
    // RACSignal *signal = [letters replayLast];
    RACSignal *signal = [letters replayLazily];

    [signal subscribeNext:^(id x) {
        NSLog(@"M1: %@", x);
    }];

    [letters sendNext:@"A"];
    [letters sendNext:@"B"];

    [signal subscribeNext:^(id x) {
        NSLog(@"P2:   %@", x);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"L3:      %@", x);
    }];

//    [letters sendNext:@"C"];
//    [letters sendNext:@"D"];
//
//    [signal subscribeNext:^(id x) {
//        NSLog(@"S4:   %@", x);
//    }];
}

- (void)replay1
{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"hello"];
        [subscriber sendNext:@"world"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"订阅完成");
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
    
    [signal subscribeNext:^(id x) {
        NSLog(@"3 == %@", x);
    }];
}

/// replay或者replayLazily只会让信号里面只发送一次，即只执一次num++，当有订阅者时就只会拿到信号当初发送的数据，不会重新发送新的，如果不用replay，则每次有订阅者都会导致racsignal执行一次
- (void)replayLazily
{
    __block int num = 0;
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id subscriber) {
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

/// 信号被`publish`的真实操作看源码可知：
/// 先创建一个`RACSubject`对象，来作为热信号，然后调用`multicast`方法，通过这个`subject`对象和`源信号`作为参数又创建了一个`RACMulticastConnection`对象，
/// 当调用`connect`方法时，`subject`会订阅`源信号`，即self。
- (void)mutableConnection
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"发送信息"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACMulticastConnection *connection = [signal publish];
    
    RACSignal *connectSignal = connection.signal;
    [connectSignal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [connectSignal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [connection connect];
}

/// 参数为RACScheduler类的对象scheduler，这个方法会返回一个Signal，它的所有事件都会传递给scheduler参数所表示的线程，而以前管道上的副作用还会在以前的线程上。这个方法主要是切换线程。
- (void)deliverOn
{
    [[[RACSignal defer:^RACSignal *{
        RACSubject *subject = [RACSubject subject];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"1：当前是%@", [NSThread isMainThread] ? @"主线程" : @"子线程");
            [subject sendNext:@"我被订阅了"];
        });
        return subject;
    }]
    deliverOn:[RACScheduler mainThreadScheduler]]
    subscribeNext:^(id x) {
        NSLog(@"2：%@ --> 当前是%@", x, [NSThread isMainThread] ? @"主线程" : @"子线程");
    }];
}

/// 比较数值流中当前值和上一个值，如果不同，就返回当前值，简单理解为“流”的值有变化时反馈变化的值，求异存同。它将这一次的值与上一次做比较，当相同时（也包括-isEqual:）被忽略掉。
- (void)distinctUntilChanged
{
    [[self.textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    } completed:^{
        NSLog(@"completed!!!!");
    }];
}

// http://blog.sunnyxx.com/2014/04/19/rac_4_filters/

/// 忽略给定的值，注意，这里忽略的既可以是地址相同的对象，也可以是-
/// isEqual:结果相同的值，也就是说自己写的Model对象可以通过重写-
/// isEqual:方法来使- ignore:生效。
- (void)ignore
{
    [[self.textField.rac_textSignal ignore:@"123"] subscribeCompleted:^{
        NSLog(@"完成");
    }];
}

/// 这个比较极端，忽略所有值，只关心Signal结束，也就是只取Comletion和Error两个消息，中间所有值都丢弃。
/// 注意，这个操作应该出现在Signal有终止条件的的情况下，如rac_textSignal这样除dealloc外没有终止条件的Signal上就不太可能用到。
- (void)ignoreValues
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@13];
        [subscriber sendNext:@4];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[signal ignoreValues] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

///  @brief
///  跳过：它会把第三条数据之前的所有数据都跳过，然后只输出第四条极其后面的数据，下面的输出结果为4，5（一次输出一条数据）
///  - skipUntilBlock:(BOOL (^)(id x))
///  和- takeUntilBlock:同理，一直跳，直到block为YES
///  - skipWhileBlock:(BOOL (^)(id x))
///  和- takeWhileBlock:同理，一直跳，直到block为NO
- (void)skip
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@13];
        [subscriber sendNext:@4];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        return nil;
    }];

    [[signalA skip:3] subscribeNext:^(id x) {
        NSLog(@"skip result = %@", x);
    }];

    ///当某一个数据符合block里面的条件时就会把它之前的数据都跳过去了，只输出后面的数据，此时block也不再执行
    [[signalA skipUntilBlock:^BOOL(id x) {
        if ([x integerValue] > 2) {
          return YES;
        }
        return NO;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// take与skip相反，它是取take的前几条数据，take:参数必须是>0的数
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
        // disposable在发送complete或者error消息后执行
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"执行disposable信号被销毁了");
        }];
    }];

    [[signal take:3] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];

    [signal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

//   - takeLast: (NSUInteger)
//
//   取最后N次的next值，注意，由于一开始不能知道这个Signal将有多少个next值，所以RAC实现它的方法是将所有next值都存起来，然后原Signal完成时再将后N个依次发送给接收者，但Error发生时依然是立刻发送的。
//
//
//   - takeUntil:(RACSignal *)
//
//   当给定的signal完成前一直取值。最简单的例子就是UITextField的rac_textSignal的实现（删减版本）:
//
//   - (RACSignal *)rac_textSignal {
//    @weakify(self);
//    return [[[[[RACSignal
//   concat:[self rac_signalForControlEvents:UIControlEventEditingChanged]]
//   map:^(UITextField *x) {
//   return x.text;
//   }]
//   takeUntil:self.rac_willDeallocSignal] // bingo!
//   }
//
//   也就是这个Signal一直到textField执行dealloc时才停止
//
//
// ###- takeUntilBlock:(BOOL (^)(id x))
//   对于每个next值，运行block，当block返回YES时停止取值，如：
//
//   [[self.inputTextField.rac_textSignal takeUntilBlock:^BOOL(NSString *value)
//   {
//   return [value isEqualToString:@"stop"];
//   }] subscribeNext:^(NSString *value) {
//   NSLog(@"current value is not `stop`: %@", value);
//   }];
//
//
//   - takeWhileBlock:(BOOL (^)(id x))
//
//   上面的反向逻辑，对于每个next值，block返回YES时才取值


/// take数据，直到xxx时候停止
- (void)takeUntil
{
    [[self.textField.rac_textSignal takeUntilBlock:^BOOL(NSString *text) {
        return [text isEqualToString:@"结束"];
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    } completed:^{
        NSLog(@"完成");
    }];
}

- (void)timer
{
    ///常用两种：
    // 1. 延迟某个时间后再做某件事
    [[RACScheduler mainThreadScheduler] afterDelay:2
                                        schedule:^{
                                            NSLog(@"你好");
                                        }];

    // 2. 每隔一段时间执行一次
    [[[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]]
      takeUntil:self.rac_willDeallocSignal]
      subscribeNext:^(NSDate *date) {
          NSLog(@"你好");
    }];
}

/// 它接收一个时间间隔interval作为参数，如果Signal发出的next事件之后interval时间内不再发出next事件，那么它返回的Signal会将这个next事件发出。也就是说，这个方法会将发送比较频繁的next事件舍弃，只保留一段“静默”时间之前的那个next事件.
/// 这个方法常用于处理输入框等信号（用户打字很快），因为它只保留用户最后输入的文字并返回一个新的Signal，将最后的文字作为next事件参数发出。
///
/// 如下0.3秒内textField输入n多个字符，0.3秒后才会把值输出，即：把0.3秒内接收到的信息到最后一块发出去
- (void)throttle
{
    [[[[self.textField.rac_textSignal ignore:@""] throttle:0.3] distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// The receiver must be a signal of signals.
/// 下面的方法会crash，因为不是信号中的信号
- (void)swithToLatest
{
    [[[[[self.textField.rac_textSignal ignore:@""] throttle:0.3] distinctUntilChanged] switchToLatest] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

///  把信号转化成事件
- (void)materialize
{
    [self.showTextButton.rac_command.executionSignals flattenMap:^RACStream *(RACSignal *subscribeSignal) {
        // materialize 把信号转化成事件
        return [[[subscribeSignal materialize] filter:^BOOL(RACEvent *event) {
            return event.finished;
        }] map:^id(id value) {
            return NSLocalizedString(@"Thanks", @"谢谢");
        }];
    }];
}

/// 当signalA和signalB都至少sendNext过一次，接下来只要其中任意一个signal有了新的内容，doA:withB这个方法就会自动被触发，withSignals:有几个signal，liftselector的选择子中就会有几个参数。
- (void)liftSelector
{
    
//    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [subscriber sendNext:@"A"];
//        });
//        return nil;
//    }];
//    
//    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        [subscriber sendNext:@"B"];
//        [subscriber sendNext:@"Another B"];
//        [subscriber sendCompleted];
//        return nil;
//    }];
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLSessionTask *task = [[ZDAFNetWorkHelper shareInstance] requestWithURL:MovieAPI params:nil httpMethod:HttpMethod_Get success:^(id  _Nullable responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLSessionTask *task = [[ZDAFNetWorkHelper shareInstance] requestWithURL:WeatherAPI params:nil httpMethod:HttpMethod_Get success:^(id  _Nullable responseObject) {
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    
    [self rac_liftSelector:@selector(doA:withB:) withSignals:signalA, signalB, nil];
}

/// collect 操作会把多个信号中所有的 next 发送的数据收集到一个 NSArray 中，然后一次性通过 next 发送给后续的环节。
/// http://fengjian0106.github.io/2016/04/28/The-Power-Of-Composition-In-FRP-Part-3/
- (void)collect
{
    RACSignal *numbers = @[@(0), @(1), @(2)].rac_sequence.signal;
    
    RACSignal *letters1 = @[@"A", @"B", @"C"].rac_sequence.signal;
    RACSignal *letters2 = @[@"X", @"Y", @"Z"].rac_sequence.signal;
    RACSignal *letters3 = @[@"M", @"N"].rac_sequence.signal;
    NSArray *arrayOfSignal = @[letters1, letters2, letters3]; //2
    
    [[[numbers map:^id(NSNumber *value) {
        return arrayOfSignal[value.integerValue];
    }] collect] subscribeNext:^(NSArray<RACSignal *> *array) {
        NSLog(@"%@, %@", [array class], array);
    } completed:^{
        NSLog(@"completed");
    }];
}

/// 该操作可将上次`reduceBlock`处理后输出的结果作为参数，传入当次`reduceBlock`操作，往往用于信号输出值的聚合处理。
/// 这个方法跟`RACSequence`中的`foldLeftWithStart:reduce:`效果是一样的
- (void)scanWithStart
{
    // 下面的例子，第一次会拿到start：0作为上一次的值和新值1相加=1，然后把这个reduce后的结果放入数组中，第二次执行时会拿到上次的1和新值2相加=3，然后把第二次reduce的结果放入数组中，第三次拿到3和新值3，然后再相加=6...，所以最终print一个装有 1，3，6，10的数组。
    RACSequence *numbers = @[@1, @2, @3, @4].rac_sequence;
    // Contains 1, 3, 6, 10
    RACSequence *sums = [numbers scanWithStart:@0 reduce:^(NSNumber *sum, NSNumber *next) {
        return @(sum.integerValue + next.integerValue);
    }];
    
    NSLog(@"%@", sums.array);
}

- (void)combinePreviousWithStart
{
    // 这个和上面的不一样，这个函数不会把reduce后的结果放入队列里作为previous。
    // 看源码可以知道，它是把reduce后的结果和next的值打包进tuple中，然后把next的值返回来作为下一次的previous值（即：其实每次在reduce里拿到的previous都是数组中的上一个元素，而不是上次reduce出来的新值），map函数处理后把reduce的值作为最终结果。
    // 所以下面的执行操作其实是：0+1，1+2，2+3，3+4
    RACSequence *numbers = @[ @1, @2, @3, @4 ].rac_sequence;
    // Contains 1, 3, 5, 7
    RACSequence *sequeue = [numbers combinePreviousWithStart:@0 reduce:^id(NSNumber *previous, NSNumber *next) {
        return @(previous.integerValue + next.integerValue);
    }];
    
    NSLog(@"%@", sequeue.array);
}

/// 聚合
- (void)aggregate
{
    RACSignal *numbers = @[@(0), @(1), @(2)].rac_sequence.signal;
    [[numbers aggregateWithStartFactory:^id{
        return [[NSMutableArray alloc] init];
    } reduce:^id(NSMutableArray *running, id next) {
        [running addObject:next ?: [NSNull null]];
        return running;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// 这个有点像collect,它也是把`sendNext`的所有结果放入一个数组中,然后以tuple结果延迟一次性全部发送;
/// 不过这里有个地方需要注意的是,从源码可以看到,当订阅者发送`sendCompleted`消息时会立即执行源信号被订阅时346行位置的`completed:`里面的那个block,然后执行`sendCompleted`,然后`timerDisposable`会被dispose,这样那个延迟方法会失效(其实根本就不执行那个方法了)
- (void)bufferWithTime
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        //[subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"3"];
        [subscriber sendNext:@"4"];
        //[subscriber sendCompleted];
        return nil;
    }];
    
    // finally print 1，2，3，4
    [[[RACSignal merge:@[signalA, signalB]] bufferWithTime:7 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1023
/// https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1473
/// They're not the same.
/// self.valueTextField.rac_newTextChannel sends values when you type in the text field, but not when you change the text in the text field from code.
/// RACChannelTo(self.uiTextField, text) sends values when you change the text in the text field from code, but not when you type(输入、键入) in the text field.
///
/// 我个人的理解:self.valueTextField.rac_newTextChannel会在输入文字时响应,但不会对textField.text = @"xx"这种直接改变文字的情况响应. 而RACChannelTo() 能够响应文字改变的情况,但是不会响应键入文字的情况.
- (void)channel {
    // 正常情况下的双向绑定(p.s RAC() 是单向的)
    RACChannelTo(self.myLabel, text, @"你好") = RACChannelTo(self.textField, text); // 输入文字时不执行
    //RACChannelTo(self.myLabel, text, @"你好") = [self.textField rac_newTextChannel]; // 输入文字时能够执行
    [[[RACObserve(self, myLabel.text) distinctUntilChanged] filter:^BOOL(NSString *value) {
        return value.length > 0;
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// `reduceApply`是对`RACTuple`进行操作，用`tuple`中的第一个元素（必须是block）作为规则，剩余的元素作为它的参数，感觉类似于`makeObjectsPerformSelector:`方法
/// 如下图所示，adder中的a和b对应于下面的100和200
- (void)reduceApply {
    //==============================**** demo1
    RACSignal *adder = [RACSignal return:^(NSNumber *a, NSNumber *b) {
        return @(a.intValue + b.intValue);
    }];
    
    RACSignal *sums = [[RACSignal combineLatest:@[ adder, [RACSignal return:@100], [RACSignal return:@1000] ]] reduceApply];
    [sums subscribeNext:^(id x) {
        // print 1100
        NSLog(@"\nreduceApply -- %@", x);
    }];
    
    //===============================*** demo2
    RACSignal *signalA = [RACSignal createSignal: ^RACDisposable *(id<RACSubscriber> subscriber) {
        id block = ^id(NSNumber *first,NSNumber *second,NSNumber *third) {
            return @(first.integerValue + second.integerValue * third.integerValue);
        };
        
        [subscriber sendNext:RACTuplePack(block, @2, @3, @8)];
        //前面的id是为了强转，否则报错
        // 这里虽然后面跟了3个参数，但是由于block中只有带一个参数，所以后面的3个参数中只会用到第一个参数而已，其他的无用
        [subscriber sendNext:RACTuplePack((id)(^NSNumber *(NSNumber *x) {
            return @(x.intValue * 10);
        }), @9, @10, @30)];
        
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"signal dispose");
        }];
    }];
    
    RACSignal *signalB = [signalA reduceApply];
    
    [signalB subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

/// `RACSequence`继承于`RACStream`，跟RACSignal是平级的；
/// 当`RACSequence`换换为`RACSignal`时最终执行的是下面的方法，
///
/// sequence里面包含几个对象，然后被订阅时就会执行多少次，
/// 原因在于下面的`reschedule()`方法，这其实就相当于是一个递归调用。
/**
 - (RACSignal *)signalWithScheduler:(RACScheduler *)scheduler {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        __block RACSequence *sequence = self;
 
        return [scheduler scheduleRecursiveBlock:^(void (^reschedule)(void)) {
            if (sequence.head == nil) {
                [subscriber sendCompleted];
                return;
            }
 
            [subscriber sendNext:sequence.head];
 
            sequence = sequence.tail;
            // 递归调用
            reschedule();
        }];
	}] setNameWithFormat:@"[%@] -signalWithScheduler: %@", self.name, scheduler];
 }
*/
- (void)sequence {
    
    RACSequence *sequence = [[@[@0, @1, @2, @3, @4, @5] rac_sequence] filter:^BOOL(id value) {
        return [value intValue] > 1;
    }];
    
    // 转换成信号
    RACSignal *signal = sequence.signal;
    
    [signal subscribeNext:^(id x) {
        // 此处会执行4次,因为上面的数组中是6个元素，但是被过滤掉了2个
        NSLog(@"%@", x);
    }];
    
    NSDictionary *dic = @{
        @"name" : @"Zero",
        @"sex" : @"man",
        @"age" : @"100",
        @"hobby" : @"cartoon"
    };
    
    [[dic rac_sequence].signal subscribeNext:^(RACTuple *x) {
        RACTupleUnpack(NSString *key, NSString *value) = x;
        NSLog(@"key:%@, value:%@", key, value);
    }];
    
    // 类似于`RACStream`类中的`scanWithStart:reduce:`方法
    // `block`中的第一个参数`accumulator`就是上一次执行`block`后返回的结果，而第二个参数`value`则是下一次执行时`sequence`中的下一个值
    [[@[@0, @1, @2, @3, @4, @5] rac_sequence] foldLeftWithStart:@100 reduce:^id(id accumulator, id value) {
        NSInteger count = [accumulator integerValue] + [value integerValue];
        return @(count);
    }];
}

#pragma mark - ------------------------
#pragma mark - Search

- (void)search
{
    [[[[[[self.textField.rac_textSignal throttle:0.3] distinctUntilChanged]
      ignore:@""] map:^id(id value) {

        return
            [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                  //  network request
                  [subscriber sendNext:value];
                  [subscriber sendCompleted];

                  return [RACDisposable disposableWithBlock:^{
                      // cancel request
                  }];
            }];
    }] switchToLatest] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
}

#pragma mark - Action

- (void)actions
{
    @weakify(self);
    self.showTextButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        [self.textField resignFirstResponder];
        self.myLabel.text = self.textField.text;
        return [RACSignal empty];
    }];
}

// a和b分别为信号发送的信息
- (void)doA:(id)a withB:(id)b
{
    NSLog(@"A:%@ and B:%@", a, b);
}

#pragma mark - 跳转

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"customID"]) {
        PushController *pushVC = segue.destinationViewController;
        __block NSUInteger i = 0;
        pushVC.command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [subscriber sendNext:@(++i)];
                [subscriber sendCompleted];
                return [RACDisposable disposableWithBlock:^{
                    NSLog(@"点击按钮信号释放了");
                }];
            }];
        }];
      
        ///The executionSignals property of RACCommand is a signal that sends a next: every time the commands start executing. The argument is the signal created by the command. So it’s a signal of signals.
        ///There is an important details to note about the executionSignals property. The signals sent here do not include error events. For those there is a special errors property.
        [[pushVC.command.executionSignals concat] subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
      
//      [[pushVC.command.executionSignals map:^id(id value) {
//          NSLog(@"%@", value);
//          return value;
//      }] subscribeNext:^(id x) {
//          NSLog(@"%@", x);
//      }];
      
        [pushVC.command.executing subscribeNext:^(id x) {
            NSString *result = ([x integerValue] == 1) ? @"执行中" : @"未执行";
            NSLog(@"%@", result);
        }];
      
    }
}


@end
