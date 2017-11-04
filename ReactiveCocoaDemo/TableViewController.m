//
//  TableViewController.m
//  ReactiveCocoaDemo
//
//  Created by Zero.D.Saber on 16/8/1.
//  Copyright © 2016年 zd. All rights reserved.
//

#import "TableViewController.h"
#import "RACController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface TableViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *data;
@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupTableDelegate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableDelegate
{
    @weakify(self);
    [[self rac_signalForSelector:@selector(tableView:didSelectRowAtIndexPath:) fromProtocol:@protocol(UITableViewDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        @strongify(self);
        NSIndexPath *indexPath = x.second;
        RACController *racController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([RACController class])];
        racController.type = indexPath.row;
        racController.navigationItem.title = self.data[indexPath.row];
#ifdef NSFoundationVersionNumber_iOS_8_0
        [self.navigationController showViewController:racController sender:self];
#else
        [self.navigationController pushViewController:racController animated:YES];
#endif
    }];
    // delegate must set on behind of `-rac_signalForSelector:fromProtocol:`
    self.tableView.delegate = (id<UITableViewDelegate>)self;
}

#pragma mark - UITableViewDataSource && UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.data[indexPath.row];
    return cell;
}

#pragma mark - Getter

- (NSArray *)data
{
    if (!_data) {
        _data = @[
          @"bind",
          @"flattenMap",
          @"flatten",
          @"map",
          @"zip",
          @"merge",
          @"combineLatestReduce",
          @"concat",
          @"then",
          @"replay",
          @"replayLazily",
          @"mutableConnection",
          @"deliverOn",
          @"distinctUntilChanged",
          @"throttle",
          @"ignore",
          @"ignoreValues",
          @"skip",
          @"take",
          @"takeUntil",
          @"timer",
          @"switchToLatest",
          @"materialize",
          @"liftSelector",
          @"collect",
          @"scanWithStart",
          @"combinePreviousWithStart",
          @"aggregate",
          @"bufferWithTime",
          @"channel",
          @"reduceApply",
          @"sequence"
        ];
    }
    return _data;
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
