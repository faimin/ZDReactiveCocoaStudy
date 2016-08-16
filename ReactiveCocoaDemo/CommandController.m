//
//  CommandController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 15/12/23.
//  Copyright © 2015年 zd. All rights reserved.
//

#import "CommandController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ZDAFNetWorkHelper.h"


@interface CommandController ()

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) NSMutableArray *mutArr;

@end

@implementation CommandController

- (void)dealloc {
    [self.mutArr removeObserver:self forKeyPath:@"mutArr"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self arrObserver];
    [self postNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)postNotification {
    __block NSUInteger i = 0;
    @weakify(self);
    [[self.sendButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification" object:@(++i)];
        
        [self willChangeValueForKey:@keypath(self.mutArr)];
        [self.mutArr addObject:@1];
        [self didChangeValueForKey:@keypath(self.mutArr)];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.mutArr.count];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@keypath(self.mutArr)];
        [self.mutArr addObject:@11];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@keypath(self.mutArr)];
    }];
}

- (void)arrObserver {
    self.mutArr = @[].mutableCopy;
    [self addObserver:self forKeyPath:@keypath(self.mutArr) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    id value = change[NSKeyValueChangeNewKey];
    NSLog(@"\n------>%@", value);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
