//
//  RotateGestureRecognizer.h
//  YBPieView
//
//  Created by 焦英博 on 2017/3/20.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RotateGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, assign) CGFloat currentAngle;
@property (nonatomic, assign) CGFloat previousAngle;

@property (nonatomic, assign) CGFloat angleIncrement; // 前后两次角度增量

@property (nonatomic, assign) CGFloat outerRadius;
@property (nonatomic, assign) CGFloat innerRadius;

@end
