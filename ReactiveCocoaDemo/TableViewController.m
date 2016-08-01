//
//  TableViewController.m
//  ReactiveCocoaDemo
//
//  Created by 符现超 on 16/8/1.
//  Copyright © 2016年 zd. All rights reserved.
//

#import "TableViewController.h"
#import "RACController.h"

@interface TableViewController ()
@property (nonatomic, strong) NSArray *data;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.data = @[@"combineLatestReduce",
                  @"flatten",
                  @"map",
                  @"zip",
                  @"merge",
                  @"skip",
                  @"take",
                  @"concat",
                  @"then",
                  @"replay",
                  @"replay1",
                  @"replayLazily",
                  @"deliverOn",
                  @"throttle",
                  @"switchToLatest",
                  @"materialize",
                  @"liftSelector",
                  @"collect"
                  ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return <#expression#>;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RACController *racController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([RACController class])];
#ifdef NSFoundationVersionNumber_iOS_8_0
    [self.navigationController showViewController:racController sender:self];
#else
    [self.navigationController pushViewController:racController animated:YES];
#endif
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
