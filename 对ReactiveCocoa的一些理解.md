###对ReactiveCocoa的一些理解
####flattenMap与map
* 推荐文章：**[RAC核心元素与信号流](http://www.jianshu.com/p/d262f2c55fbe) && [细说ReactiveCocoa的冷信号与热信号（三）：怎么处理冷信号与热信号](http://tech.meituan.com/talk-about-reactivecocoas-cold-signal-and-hot-signal-part-3.html)**

本文好多是参考刚才的推荐文章来理解的，在此感谢**godyZ**。
> 
> 具体来看源码（为方便理解，去掉了源代码中RACDisposable, @synchronized, @autoreleasepool相关代码)。当新信号N被外部订阅时，会进入信号N 的didSubscribeBlock( 1处)，之后订阅原信号O (2)，当原信号O有值输出后就用bind函数传入的bindBlock将其变换成中间信号M (3), 并马上对其进行订阅(4)，最后将中间信号M的输出作为新信号N的输出 (5)。

```objc
(RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
  return [RACSignal createSignal:^(id<RACSubscriber> subscriber) { // (1)
      RACStreamBindBlock bindingBlock = block();

      [self subscribeNext:^(id x) { // (2)
          BOOL stop = NO;
          id middleSignal = bindingBlock(x, &stop); // (3)

          if (middleSignal != nil) {
              RACDisposable *disposable = [middleSignal subscribeNext:^(id x) { // (4)
                  [subscriber sendNext:x]; // (5)
              } error:^(NSError *error) {
                  [subscriber sendError:error];
              } completed:^{
                  [subscriber sendCompleted];
              }];
          }
      } error:^(NSError *error) {
          [subscriber sendError:error];
      } completed:^{
          [subscriber sendCompleted];
      }];

   	return nil;
  }];
}
```

* `flattenMap`其实就是对`bind：`方法进行了一些安全检查，它最终返回的是bindBlock执行后生成的那个中间signal又被订阅后传递出的值的信号，而map方法返回的是bindBlock的执行结果生成的那个信号，没有再加工处理（即被订阅，再发送值）

```objc
- (instancetype)flattenMap:(RACStream * (^)(id value))block {
	Class class = self.class;

	return [[self bind:^{
		/// @return 返回的是RACStreamBindBlock
		/// @discussion
		///
		/// 跟`bind：`方法中的代码对应起来如下：
		/// BOOL stop = NO;
     	/// id middleSignal = bindingBlock(x, &stop);
     	///
     	/// 可以看出bindBlock中的x是原信号被subscribe后传出的值，即对应下面的value
     	/// 也即flattenMap block中执行后传出的值，
     	/// 即上面的(RACStream * (^ block)(id value))中的value
     	/// 综上所述：flattenMap方法中传进来的那个block参数值就是原信号被订阅后发送的值
		return ^(id value, BOOL *stop) {
			id stream = block(value) ?: [class empty];
			NSCAssert([stream isKindOfClass:RACStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);

			return stream;
		};
	}] setNameWithFormat:@"[%@] -flattenMap:", self.name];
}
```
* 下面是`map`方法的源码，可以看出，`map`只是对`flattenMap`传出的value（即原信号传出的值）进行了mapBlock操作，并没有再进行订阅操作，即并不像`bind：`一样再次对原信号进行bindBlock后生成的中间信号进行订阅。

```objc
- (instancetype)map:(id (^)(id value))block {
	NSCParameterAssert(block != nil);

	Class class = self.class;
	
	return [[self flattenMap:^(id value) {
		return [class return:block(value)];
	}] setNameWithFormat:@"[%@] -map:", self.name];
}
```

> `flatten`: 该操作主要作用于信号的信号。原信号O作为信号的信号，在被订阅时输出的数据必然也是个信号(signalValue)，这往往不是我们想要的。当我们执行[O flatten]操作时，因为flatten内部调用了flattenMap (1)，flattenMap里对应的中间信号就是原信号O输出的signalValue (2)。按照之前分析的经验，在flattenMap操作中新信号N输出的结果就是各中间信号M输出的集合。因此在flatten操作中新信号N被订阅时输出的值就是原信号O的各个子信号输出值的集合。
> 
```objc
- (instancetype)flatten
{
    return [self flattenMap:^(RACSignal *signalValue) { // (1)
        return [signalValue]; // (2)
    };
}
```

#### （摘自美团）简单分析一下 `- (RACMulticastConnection *)multicast:(RACSubject *)subject;`方法：
* 1、当 `RACSignal` 类的实例调用 `- (RACMulticastConnection *)multicast:(RACSubject *)subject` 时，以 `self` 和 `subject` 作为构造参数创建一个 `RACMulticastConnection` 实例。
* 2、`RACMulticastConnection` 构造的时候，保存 `source` 和 `subject` 作为成员变量，创建一个 `RACSerialDisposable` 对象，用于取消订阅。
* 3、当 `RACMulticastConnection` 类的实例调用 `- (RACDisposable *)connect` 这个方法的时候，判断是否是第一次。如果是的话 用 `_signal` 这个成员变量来订阅 `sourceSignal` 之后返回 `self.serialDisposable` ,否则直接返回 `self.serialDisposable` 。这里面订阅 `sourceSignal` 是重点。
* 4、`RACMulticastConnection` 的 `signal` 只读属性，就是一个热信号，订阅这个热信号就避免了各种副作用的问题。它会在 `- (RACDisposable *)connect` 第一次调用后，根据 sourceSignal 的订阅结果来传递事件。
* 5、想要确保第一次订阅就能成功订阅 `sourceSignal` ，可以使用 `- (RACSignal *)autoconnect` 这个方法，它保证了第一个订阅者触发 `sourceSignal` 的订阅，也保证了当返回的信号所有订阅者都关闭连接后 `sourceSignal` 被正确关闭连接。

----
#### 附：`ReactiveCocoa`和`RxSwift` API图，引用自[FRPCheatSheeta](https://github.com/aiqiuqiu/FRPCheatSheeta)
>
**ReactiveCocoa-Objc**
----
![ReactiveCocoa-Objc](http://ww1.sinaimg.cn/large/006tNbRwjw1f69ss3l0y4j31jf1cpwtm.jpg)
**ReactiveCocoa-Swift**
----
![ReactiveCocoaV4.x-Swift.png](http://ww4.sinaimg.cn/large/006tNbRwjw1f69u9n630vj31kw10nk1g.jpg)
**RxSwift**
----
![RXSwift.png](http://ww2.sinaimg.cn/large/006tNbRwjw1f69u2fugtjj317k1n1tis.jpg)

