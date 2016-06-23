###对ReactiveCocoa的一些理解
#####flattenMap与map
* 推荐文章：**[RAC核心元素与信号流](http://www.jianshu.com/p/d262f2c55fbe)**
* `flattenMap`其实就是对`bind：`方法进行了一些安全检查

> 本文好多是参考刚才的推荐文章来理解的，在此非常感谢@godyZ。
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

   return nil
  }];
}
```

* `flattenMap`方法最终返回的是bindBlock执行后生成的那个中间signal又被订阅后传递出的值的信号，而map方法返回的是bindBlock的执行结果生成的那个信号，没有再加工处理（即被订阅，再发送值）
* 下面是`map`方法的源码，可以看出，`map`只是对`flattenMap`传出的value（即`bind：`中的中间信号）进行了mapBlock操作，并没有再进行订阅操作，即并不像`bind：`一样再次对原信号进行bindBlock后生成的中间信号进行订阅。

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



