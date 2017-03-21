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

static CGFloat degreesToRadians (CGFloat degrees){
    return degrees * M_PI / 180;
}

CGFloat incrementOfPower(CGFloat p) {
    CGFloat absp = fabs(p);
    CGFloat degrees = 0;
    if (absp <= 0.05) {
        degrees = 30;
    } else if (absp <= 0.1) {
        degrees = 70;
    } else if (absp <= 0.3) {
        degrees = 120;
    } else if (absp <= 0.6) {
        degrees = 170;
    } else if (absp <= 0.9) {
        degrees = 260;
    } else {
        degrees = 400;
    }
    CGFloat inc = degreesToRadians(degrees);
    inc = p < 0 ? -inc : inc;
    return inc;
}
