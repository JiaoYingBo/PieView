//
//  YBPieViewMath.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/20.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "YBPieViewMath.h"

PolarCoordinate decartToPolar(CGPoint center, CGPoint point){
    double x = point.x - center.x;
    double y = point.y - center.y;
    
    PolarCoordinate polar;
    polar.radius = sqrt(pow(x, 2.0) + pow(y, 2.0));
    polar.angle = acos(x/polar.radius);
    if (y < 0) polar.angle = 2 * M_PI - polar.angle;
    return polar;
}
