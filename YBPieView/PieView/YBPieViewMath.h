//
//  YBPieViewMath.h
//  YBPieView
//
//  Created by 焦英博 on 2017/3/20.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct{
    double radius;
    double angle;
} PolarCoordinate;

PolarCoordinate decartToPolar(CGPoint center, CGPoint point);

CGFloat incrementOfPower(CGFloat p);
