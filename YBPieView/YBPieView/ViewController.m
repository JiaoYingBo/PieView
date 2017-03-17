//
//  ViewController.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "ViewController.h"
#import "YBPieView.h"

@interface ViewController () <YBPieViewDataSource>

@property (nonatomic, strong) YBPieView *cView;
@property (nonatomic, strong) NSMutableArray *datas;
@property (nonatomic, strong) NSArray *colorArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.datas = [NSMutableArray arrayWithArray:@[@10,@15,@23,@45,@35]];
    self.colorArray =  [NSArray arrayWithObjects:[UIColor redColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor greenColor],[UIColor blueColor],nil];
    
    YBPieView *chart = [[YBPieView alloc] initWithFrame:CGRectMake(85, 50, 200, 200)];
    [self.view addSubview:chart];
    chart.dataSource = self;
    chart.animationDuration = 1;
    [chart reloadData];
    self.cView = chart;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.datas.count) {
        [self.datas removeAllObjects];
    } else {
        self.datas = [NSMutableArray arrayWithArray:@[@10,@15,@23,@45,@35]];
    }
    [self.cView reloadData];
}

#pragma mark - PieView Data Source

- (NSUInteger)numberOfSlicesInPieChart:(YBPieView *)pieChart {
    return self.datas.count;
}

- (CGFloat)pieChart:(YBPieView *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    return [self.datas[index] intValue];
}

- (UIColor *)pieChart:(YBPieView *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    return self.colorArray[index];
}

- (NSString *)pieChart:(YBPieView *)pieChart imageNameForSliceAtIndex:(NSUInteger)index {
    NSString *image = nil;
    switch (index) {
        case 0:
            image = @"1";
            break;
        case 1:
            image = @"2";
            break;
        case 2:
            image = @"3";
            break;
        case 3:
            image = @"4";
            break;
        case 4:
            image = @"5";
            break;
            
        default:
            break;
    }
    return image;
}

@end
