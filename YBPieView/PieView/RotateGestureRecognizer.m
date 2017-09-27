//
//  RotateGestureRecognizer.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/20.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "RotateGestureRecognizer.h"
#import "YBPieViewMath.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

static const NSInteger sensitivity = 6; // 连续触发6次touchMoved才开始此手势

@implementation RotateGestureRecognizer {
    NSInteger _movedTimes;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[event touchesForGestureRecognizer:self] count] > 1) {
        self.state = UIGestureRecognizerStateFailed;
    }
    if (_innerRadius) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        PolarCoordinate polar = decartToPolar(center, point);
        if (polar.radius < _innerRadius || polar.radius > _outerRadius) {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
    _movedTimes = 0;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // 连续触发sensitivity次以上才触发手势，以便区分小幅度旋转手势和单击手势
    if (_movedTimes++ > sensitivity) {
        if (self.state == UIGestureRecognizerStatePossible) {
            [self setState:UIGestureRecognizerStateBegan];
        } else {
            [self setState:UIGestureRecognizerStateChanged];
        }
    }
    
    UIView *view = self.view;
    UITouch *touch = [touches anyObject];
    CGPoint center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CGPoint currentTouchPoint = [touch locationInView:view];
    CGPoint previousTouchPoint = [touch previousLocationInView:view];
    
    CGFloat increment = atan2f(currentTouchPoint.y - center.y, currentTouchPoint.x - center.x) - atan2f(previousTouchPoint.y - center.y, previousTouchPoint.x - center.x);
    
    self.angleIncrement = increment;
    
    PolarCoordinate polar = decartToPolar(center, currentTouchPoint);
    self.currentAngle = polar.angle;
    self.previousAngle = decartToPolar(center, previousTouchPoint).angle;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_movedTimes > sensitivity) {
        if (self.state == UIGestureRecognizerStateChanged) {
            [self setState:UIGestureRecognizerStateEnded];
        } else {
            [self setState:UIGestureRecognizerStateFailed];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setState:UIGestureRecognizerStateFailed];
}

@end
