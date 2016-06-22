###对ReactiveCocoa的一些理解
#####flattenMap与map
* 推荐文章：**[RAC核心元素与信号流](http://www.jianshu.com/p/d262f2c55fbe)**
* flattenMap其实就是对`bind：`方法进行了一些安全检查

> 这些摘自上文的推荐文章。具体来看源码（为方便理解，去掉了源代码中RACDisposable, @synchronized, @autoreleasepool相关代码)。当新信号N被外部订阅时，会进入信号N 的didSubscribeBlock( 1处)，之后订阅原信号O (2)，当原信号O有值输出后就用bind函数传入的bindBlock将其变换成中间信号M (3), 并马上对其进行订阅(4)，最后将中间信号M的输出作为新信号N的输出 (5)。

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

* flattenMap方法最终返回的是bindBlock执行后生成的那个中间signal又被订阅后传递出的值的信号，而map方法返回的是bindBlock的执行结果生成的那个信号，没有再加工处理（即被订阅，再发送值）

