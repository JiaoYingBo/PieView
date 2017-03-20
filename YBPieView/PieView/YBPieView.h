//
//  YBPieView.h
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YBPieView;
@protocol YBPieViewDataSource <NSObject>

@required
- (NSUInteger)numberOfSlicesInPieChart:(YBPieView *)pieChart;
- (CGFloat)pieChart:(YBPieView *)pieChart valueForSliceAtIndex:(NSUInteger)index;
- (NSString *)pieChart:(YBPieView *)pieChart imageNameForSliceAtIndex:(NSUInteger)index;

@optional
- (UIColor *)pieChart:(YBPieView *)pieChart colorForSliceAtIndex:(NSUInteger)index;
- (NSString *)pieChart:(YBPieView *)pieChart textForSliceAtIndex:(NSUInteger)index;

@end

@interface YBPieView : UIView
#ifdef __IPHONE_10_0
<CAAnimationDelegate>
#endif

@property (nonatomic, weak) id<YBPieViewDataSource> dataSource;
@property (nonatomic, assign) CGFloat startPieAngle;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) CGFloat pieLineWidth;
@property (nonatomic, assign) CGFloat selectedOffsetRadius;

- (void)reloadData;

@end
