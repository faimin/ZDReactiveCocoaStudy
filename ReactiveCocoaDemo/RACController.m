//
//  ViewController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/8/22.
//  Copyright (c) 2015年 zd. All rights reserved.
//

#import "PushController.h"
#import "RACController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ZDAFNetWorkHelper.h"
#import <LxDBAnything.h>

#define FORMATSTRING(FORMAT, ...)                   \
  ([NSString stringWithFormat:FORMAT, ##__VA_ARGS__])


@interface RACController ()

@property(weak, nonatomic) IBOutlet UITextField *textField;
@property(weak, nonatomic) IBOutlet UIButton *pushButton;

@end

@implementation RACController

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

#pragma mark - Function

- (void)signal
{
//    [self zip];

//    [self merge];

    //[self skip];

    //[self take];

    //[self concat];

    //[self replay];

    //[self replay1];

    //[self replayLazily];

    //[self deliverOn];
    
    [self throttle];
    
}

#pragma mark - Signals
#pragma mark -
// RACSignal底层实现：
// 1.创建信号，首先把didSubscribe保存到信号中，还不会触发。
// 2.当信号被订阅，也就是调用signal的subscribeNext:nextBlock
// 2.1 subscribeNext内部会创建订阅者subscriber，并且把nextBlock保存到subscriber中。
// 2.2 subscribeNext内部会调用siganl的didSubscribe
// 3.siganl的didSubscribe中调用[subscriber sendNext:@1];
// 3.1 sendNext底层其实就是执行subscriber的nextBlock


///将一组Signal发出的最新的事件合并成一个Signal，每当这组Signal发出新事件时，reduce的block会执行，将所有新事件的值合并成一个值，并当做合并后Signal的事件发出去。
///这个方法会返回合并后的Signal。
///reduce的block中参数，其实是与combineLatest中数组元素一一对应的
- (void)combineLatestReduce
{
    
}

/**
 *  把多个信号合并成一个信号，任何一个信号有新值的时候就会调用
 *  和combine reduce差不多,总是返回最新的信号
 */
- (void)merge
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"3"];
        //[subscriber sendNext:@"4"];
        [subscriber sendCompleted];
        return nil;
    }];
    
//    [RACSignal combineLatest:[signalA, signalB] reduce:^id(NSString *a , NSString * b){
//        
//    }];
    
    [[signalA merge:signalB] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    }];
}

/**
 *  @brief  压缩: 把两个信号中的数据连到一起，生成一个RACTuple，[A
 * zipWith:B]中A和B至少发送过一次消息，zip才会把他们打包成一个tuple
 *
 *  比如下面的demo，如果打开signalB中的sendNext:@"4",
 * 则会输出2次，输出结果分别为13，24，如果不打开则只输出一个结果：13，相当于两个信号中的数据会一一映射，当对应的数据缺失时则不执行压缩操作
 *
 *  [C zipWith:D]可以比喻成一对平等恩爱的夫妻，两个人是“绑在一起“的关系来组成一个家庭，决定一件事（value）时必须两个人都提出意见（当且仅当C和D同时都产生了值的时候，一个value才被输出，C、D只有其中一个有值时会挂起，等待另一个的值，所以输出都是一对值（RACTuple）），当夫妻只要一个人先挂了（completed）这个家庭（组合起来的RACStream）就宣布解散（也就是无法凑成一对输出时就终止）
 */
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
           LxDBAnyVar(@"取消订阅signalA");
        }];
    }];


    [[signalB zipWith:signalA] subscribeNext:^(id x) {
        RACTupleUnpack(NSString * str1, NSString * str2) = x;
        NSString *str = FORMATSTRING(@"%@%@", str1, str2);
        NSLog(@"%@,\n %@", x, str);
    }];
}

/**
 *  @brief  合并：把一个信号传递的数据拼接到另一个信号的数据上
 *
 *  [A concat:B]中只有A信号执行完complete之后才会执行B，如果A失败（比如执行了sendError），则B永远不会执行
 *  A和B像皇上和太子的关系，A是皇上，B是太子。皇上健在的时候统治天下发号施令（value），太子就候着，不发号施令（value），当皇上挂了（completed），太子登基当皇上，此时发出的号令（value）是太子的。
 *
 *  下面的返回结果是ABCDEFGHI123456789
 */
- (void)concat
{
    RACSequence *letters =
      [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers =
      [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;

    RACSequence *concat = [letters concat:numbers];

    NSLog(@"%@", [concat array]);
}

///当一个订阅者被发送了completed事件后，then:方法才会执行，订阅者会订阅then:方法返回的Signal，这个Signal是在block中返回的。
///这样优雅的实现了从一个Signal到另一个Signal的订阅。
- (void)then
{
    
}

/**
 *  重新运行：当有新的订阅者时信号会重新发送以前发送过的数据给这个订阅者
 *  下面的例子中，如果不加replay，则第二个订阅者不会受到它上面已经发送过的信号（即s2不执行，不打印任何数据），加上replay后它会收以前已经发送过的A和B两个数据。
 *  replayLast会把最后一个信号数据发给后来的订阅者，如下，s2只会输出B
 *  replayLazily
 * 不会重新执行,他与其他2个不同之处是RAC中的信号只有在被订阅后才会执行，而其他的只要执行到那就会执行，就跟do-while一样
 *  http://spin.atomicobject.com/2014/06/29/replay-replaylast-replaylazily/
 */
- (void)replay
{
    ///// RACSubject是RACSignal的子类，它可以快速创建一个信号，用来发送信息
    RACSubject *letters = [RACSubject
          subject];
    // RACSignal *signal = [letters replay];
    // RACSignal *signal = [letters replayLast];
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
            // TODO:
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

/**
 *  参数为RACScheduler类的对象scheduler，这个方法会返回一个Signal，它的所有事件都会传递给scheduler参数所表示的线程，而以前管道上的副作用还会在以前的线程上。这个方法主要是切换线程。
 */
- (void)deliverOn
{
}

/**
 *  比较数值流中当前值和上一个值，如果不同，就返回当前值，简单理解为“流”的值有变化时反馈变化的值，求异存同。它将这一次的值与上一次做比较，当相同时（也包括-isEqual:）被忽略掉。
 */
- (void)distinctUntilChanged
{
    [[self.textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    } completed:^{
        LxDBAnyVar(@"completed!!!!");
    }];
}

// http://blog.sunnyxx.com/2014/04/19/rac_4_filters/

/**
 *  忽略给定的值，注意，这里忽略的既可以是地址相同的对象，也可以是-
 * isEqual:结果相同的值，也就是说自己写的Model对象可以通过重写-
 * isEqual:方法来使- ignore:生效。
 */
- (void)ignore
{
    [[self.textField.rac_textSignal ignore:@"123"] subscribeCompleted:^{
        LxDBAnyVar(@"完成");
    }];
}

/**
 *  这个比较极端，忽略所有值，只关心Signal结束，也就是只取Comletion和Error两个消息，中间所有值都丢弃。
 *  注意，这个操作应该出现在Signal有终止条件的的情况下，如rac_textSignal这样除dealloc外没有终止条件的Signal上就不太可能用到。
 */
- (void)ignoreValues
{
}

/**
 *  @brief
 * 跳过：它会把第三条数据之前的所有数据都跳过，然后只输出第四条极其后面的数据，下面的输出结果为4，5（一次输出一条数据）
 *
 *
 *  - skipUntilBlock:(BOOL (^)(id x))
 *
 *  和- takeUntilBlock:同理，一直跳，直到block为YES
 *
 *  - skipWhileBlock:(BOOL (^)(id x))
 *
 *  和- takeWhileBlock:同理，一直跳，直到block为NO
 */
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

/**
 *  take与skip相反，它是取take的前几条数据
 */
- (void)take
{
    RACSignal *signal =
    [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"你好"];
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@13];
        [subscriber sendNext:@4];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        // disposable在发送complete或者error消息后执行
        return [RACDisposable disposableWithBlock:^{
            LxPrintAnything(执行disposable信号被销毁了);
        }];
    }];

    [[signal take:3] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    }];

    [signal subscribeNext:^(id x) {
        LxDBAnyVar(x);
    }];
}

//   - takeLast: (NSUInteger)
//
//   取最后N次的next值，注意，由于一开始不能知道这个Signal将有多少个next值，所以RAC实现它的方法是将所有next值都存起来，然后原Signal完成时再将后N个依次发送给接收者，但Error发生时依然是立刻发送的。
//
//
//   - takeUntil:(RACSignal *)
//
//   当给定的signal完成前一直取值。最简单的栗子就是UITextField的rac_textSignal的实现（删减版本）:
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

/**
*  take数据，直到xxx时候停止
*/
- (void)takeUntil
{
    [[self.textField.rac_textSignal takeUntilBlock:^BOOL(NSString *text) {
        return [text isEqualToString:@"结束"];
    }] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    } completed:^{
        LxDBAnyVar(@"完成");
    }];
}

- (void)timer
{
    ///常用两种：
    // 1. 延迟某个时间后再做某件事
    [[RACScheduler mainThreadScheduler] afterDelay:2
                                        schedule:^{
                                            LxDBAnyVar(@"你好");
                                        }];

    // 2. 每个一定长度时间做一件事
    [[[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]]
      takeUntil:self.rac_willDeallocSignal]
      subscribeNext:^(NSDate *date) {
          LxDBAnyVar(@"你好");
    }];
}

// MARK：把网络请求改成信号控制
//- (RACSignal *)getUserByEmail:(NSString *)email {
//    return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
//        NSString *path = @"https://your.server.address/api/user";
//        NSDictionary *params = @{ @"email":email };
//
//        NSURLSessionDataTask *task = [self dataTaskWithHTTPMethod:@"GET"
//        URLString:path parameters:params success:^(NSURLSessionDataTask *task,
//        id responseObject) {
//            NSError *error = nil;
//            User *user = [MTLJSONAdapter modelOfClass:[User class]
//            fromJSONDictionary:responseObject error:&error];
//            if (error) {
//                [subscriber sendError:error];
//            } else {
//                [subscriber sendNext:user];
//                [subscriber sendCompleted];
//            }
//        } failure:^(NSURLSessionDataTask *task, NSError *error) {
//            [subscriber sendError:error];
//        }];
//
//        [task resume];
//
//        return [RACDisposable disposableWithBlock:^{
//            [task cancel];
//        }];
//    }];
//}

/// 它接收一个时间间隔interval作为参数，如果Signal发出的next事件之后interval时间内不再发出next事件，那么它返回的Signal会将这个next事件发出。也就是说，这个方法会将发送比较频繁的next事件舍弃，只保留一段“静默”时间之前的那个next事件.
/// 这个方法常用于处理输入框等信号（用户打字很快），因为它只保留用户最后输入的文字并返回一个新的Signal，将最后的文字作为next事件参数发出。
///
/// 如下0.3秒内textField输入n多个字符，0.3秒后才会把值输出，即：把0.3秒内接收到的信息到最后一块发出去
- (void)throttle
{
    [[[[self.textField.rac_textSignal ignore:@""] throttle:0.3] distinctUntilChanged] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    }];
}

/// The receiver must be a signal of signals.
/// 下面的方法会crash，因为不是信号中的信号
- (void)swithToLatest
{
    [[[[[self.textField.rac_textSignal ignore:@""] throttle:0.3] distinctUntilChanged] switchToLatest] subscribeNext:^(id x) {
        LxDBAnyVar(x);
    }];
}




#pragma mark - Search

- (void)search {
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
        LxDBAnyVar(x);
    }];
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
                    LxPrintAnything(点击按钮信号释放了);
                }];
            }];
        }];
      
        ///The executionSignals property of RACCommand is a signal that sends a next: every time the commands start executing. The argument is the signal created by the command. So it’s a signal of signals.
        ///There is an important details to note about the executionSignals property. The signals sent here do not include error events. For those there is a special errors property.
        [[pushVC.command.executionSignals concat] subscribeNext:^(id x) {
            LxDBAnyVar(x);
        }];
      
//      [[pushVC.command.executionSignals map:^id(id value) {
//          LxDBAnyVar(value);
//          return value;
//      }] subscribeNext:^(id x) {
//          LxDBAnyVar(x);
//      }];
      
        [pushVC.command.executing subscribeNext:^(id x) {
            NSString *result = ([x integerValue] == 1) ? @"执行中" : @"未执行";
            LxDBAnyVar(result);
        }];
      
    }
}


@end
