//
//  CircleLayer.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "CircleLayer.h"

@implementation CircleLayer

// CA生成关键帧是通过拷贝CALayer进行的，在拷贝时，只能拷贝原有的（系统的，非自定义的）属性，不能拷贝自定义的属性或持有的对象等等，因此需要重载initWithLayer来手动拷贝我们需要拷贝的东西。
- (instancetype)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer]) {
        if ([layer isKindOfClass:[CircleLayer class]]) {
            self.startAngle = [(CircleLayer *)layer startAngle];
            self.endAngle = [(CircleLayer *)layer endAngle];
        }
    }
    return self;
}

@end
