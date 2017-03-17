//
//  CircleLayer.h
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CircleLayer : CAShapeLayer

@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;

@end
