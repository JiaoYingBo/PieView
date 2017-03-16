//
//  YBPieView.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "YBPieView.h"
#import "CircleLayer.h"

typedef struct{
    double radius;
    double angle;
} PolarCoordinate;

static PolarCoordinate decartToPolar(CGPoint center, CGPoint point){
    double x = point.x - center.x;
    double y = point.y - center.y;
    
    PolarCoordinate polar;
    polar.radius = sqrt(pow(x, 2.0) + pow(y, 2.0));
    polar.angle = acos(x/polar.radius);
    if(y < 0) polar.angle = 2 * M_PI - polar.angle;
    return polar;
}

@interface YBPieView () {
    NSTimer *_animationTimer;
    NSMutableArray *_animations;
    CGPoint _pieCenter;
    CGFloat _pieRadius;
    NSInteger _selectedIndex;
}

@end

@implementation YBPieView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _animations = [[NSMutableArray alloc] init];
        _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        _pieRadius = 70;
        _animationDuration = 3;
        _startPieAngle = 1;
        _pieWidth = 30;
        _selectedIndex = -1;
        _selectedOffsetRadius = 7.0;
    }
    return self;
}

- (void)reloadData {
    [self sublayersInit];
    
    double lastStartAngle = 0.0;
    double lastEndAngle = 0.0;
    
    NSUInteger dataCount = [_dataSource numberOfSlicesInPieChart:self];
    
    double dataSourceSum = 0.0;
    double dataSources[dataCount];
    for (int index = 0; index < dataCount; index++) {
        dataSources[index] = [_dataSource pieChart:self valueForSliceAtIndex:index];
        dataSourceSum += dataSources[index];
    }
    
    double angleArray[dataCount];
    for (int index = 0; index < dataCount; index++) {
        double percent;
        if (dataSourceSum == 0) {
            percent = 0;
        } else {
            percent = dataSources[index] / dataSourceSum;
        }
        angleArray[index] = M_PI * 2 * percent;
    }
    
    // 修改图层树之前，通过给CATrasaction类发送begin消息来创建一个显式事务，修改完之后发送comit消息。
    [CATransaction begin];
    [CATransaction setAnimationDuration:_animationDuration];
    self.userInteractionEnabled = NO;
    
    BOOL isOnEnd = (self.layer.sublayers.count && (dataCount == 0 || dataSourceSum <= 0));
    if(isOnEnd) {
        for(CircleLayer *layer in self.layer.sublayers){
            /*
             给每个layer创建动画，动画一旦被添加到layer上，就会开始执行
             由于这个动画属性不是系统的，所以不会产生动画效果，只会产生动画过程中的值
             我们可以根据这些值画出实时图像，这样就形成了“动画”
             其实跟自定义控件道理是一样的，只不过自定义控件是自己根据触摸来计算值，这里是系统根据动画来计算值，最后都是要画的
             
             -----以下是这个程序的做法-----
             动画开始之后，手动创建定时器，每秒触发60次绘制图形，绘制方法：
             创建UIBezierPath，把它赋给layer，这样layer就会自己绘制出path对应的图形，相当于关键帧动画
             
             系统的绘制方法：创建一个贝塞尔曲线，把path赋给layer，图像就出来了
             但如果加个系统属性的动画到layer上，就会自动产生动画
             */
            [self createAnimationWithKeyPath:@"startAngle" fromValue:@(0) toValue:@(_startPieAngle) layer:layer];
            [self createAnimationWithKeyPath:@"endAngle" fromValue:@(0) toValue:@(_startPieAngle) layer:layer];
        }
        [CATransaction commit];
        return;
    }
    
    BOOL isOnStart = dataCount && self.layer.sublayers.count == 0;
    
    for (int index = 0; index < dataCount; index ++) {
        CircleLayer *layer;
        if (isOnStart) {
            layer = [self createCircleLayerWithIndex:index];
            [self.layer addSublayer:layer];
        } else {
            layer = (CircleLayer *)self.layer.sublayers[index];
        }
        layer.isSelected = NO;
        double angle = angleArray[index];
        lastEndAngle += angle;
        double startAngle = _startPieAngle + lastStartAngle;
        double endAngle = _startPieAngle + lastEndAngle;
        
        layer.lineWidth = _pieWidth;
        layer.currentRadius = _pieRadius;
        layer.value = dataSources[index];
        layer.percentage = dataSourceSum ? layer.value/dataSourceSum : 0;
        
        UIColor *color = nil;
        if ([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)]) {
            color = [_dataSource pieChart:self colorForSliceAtIndex:index];
        }
        if (!color) {
            color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
        }
        layer.strokeColor = color.CGColor;
        layer.fillColor = [UIColor clearColor].CGColor;
        
        [self createAnimationWithKeyPath:@"startAngle" fromValue:@(_startPieAngle) toValue:@(startAngle) layer:layer];
        [self createAnimationWithKeyPath:@"endAngle" fromValue:@(_startPieAngle) toValue:@(endAngle) layer:layer];
        
        lastStartAngle = lastEndAngle;
    }
    
    self.userInteractionEnabled = YES;
    [CATransaction commit];
    
}

- (void)sublayersInit {
    _selectedIndex = -1;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CircleLayer *layer = (CircleLayer *)obj;
        if (layer.isSelected) {
            [self setDeselectedAtIndex:idx];
        }
    }];
}

- (CircleLayer *)createCircleLayerWithIndex:(NSInteger)index {
    CircleLayer *layer = [CircleLayer layer];
    CALayer *imgLayer = [CALayer layer];
    imgLayer.contentsScale = [UIScreen mainScreen].scale;
    imgLayer.anchorPoint = CGPointMake(0.5, 0.5);
    imgLayer.backgroundColor = [UIColor clearColor].CGColor;
    imgLayer.frame = CGRectMake(0, 0, 20, 20);
    imgLayer.position = CGPointMake(_pieCenter.x + (_pieRadius * cos(0)), _pieCenter.y + (_pieRadius * sin(0)));
    NSString *imageName = [self.dataSource pieChart:self imageNameForSliceAtIndex:index];
    imgLayer.contents = (id)[UIImage imageNamed:imageName].CGImage;
    [layer addSublayer:imgLayer];
    return layer;
}

- (void)createAnimationWithKeyPath:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to layer:(CALayer *)layer {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [layer.presentationLayer valueForKey:key];
    if (!currentAngle) {
        currentAngle = from;
    }
    anim.fromValue = currentAngle;
    anim.toValue = to;
    anim.delegate = self;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [layer addAnimation:anim forKey:key];
    // 设置结束值，这样动画结束之后就会停留在结束位置，而不会返回初始位置，这里一定要在添加动画之后设置
    [layer setValue:to forKey:key];
}

#pragma mark - CAAnimation delegate and timer

- (void)animationDidStart:(CAAnimation *)anim {
    self.userInteractionEnabled = NO;
    if (!_animationTimer) {
        static float timeInterval = 1.0/60.0;
        _animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
    }
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.userInteractionEnabled = YES;
    [_animations removeObject:anim];
    if (_animations.count == 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

- (void)timerFired {
    NSArray *sliceLayerArray = self.layer.sublayers;
    
    [sliceLayerArray enumerateObjectsUsingBlock:^(CircleLayer *layer, NSUInteger idx, BOOL *stop) {
        CGFloat currentStartAngle = [[layer.presentationLayer valueForKey:@"startAngle"] doubleValue];
        CGFloat currentEndAngle = [[layer.presentationLayer valueForKey:@"endAngle"] doubleValue];
        
        // 转盘动画
        // UIBezierPath中的clockwise与实际相同，而QuardzCore中的相反，因为苹果的坐标系原点是左上角而不是数学中的左下角
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:_pieCenter radius:_pieRadius startAngle:currentStartAngle endAngle:currentEndAngle clockwise:1];
        layer.path = path.CGPath;
        
        // 图片动画
        CALayer *imgLayer = layer.sublayers[0];
        CGFloat interpolatedMidAngle = (currentEndAngle + currentStartAngle) / 2;
        [CATransaction setDisableActions:YES];
        // position是锚点在父视图中的位置，而它的锚点是(0.5,0.5)
        [imgLayer setPosition:CGPointMake(_pieCenter.x + (_pieRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_pieRadius * sin(interpolatedMidAngle)))];
        [CATransaction setDisableActions:NO];
        
        // 图片显式与否（0.2约等于11度）
        if (currentEndAngle - currentStartAngle <= 0.2) {
            imgLayer.hidden = YES;
        } else {
            imgLayer.hidden = NO;
        }
    }];
}

#pragma mark - touch actions

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    PolarCoordinate polar = decartToPolar(_pieCenter, point);
    NSLog(@"-->%f",polar.angle);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    NSInteger index = [self getSelectedIndexOnTouch:point];
    if (index != -1) {
        [self notifyDelegateFrom:_selectedIndex to:index];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //
}

#pragma mark - notify delegate

- (void)notifyDelegateFrom:(NSInteger)fromSeletion to:(NSInteger)toSeletion {
    if (fromSeletion != toSeletion) {
        if (fromSeletion != -1) {
            // delegate
            [self setDeselectedAtIndex:fromSeletion];
        }
        if (toSeletion != -1) {
            // delegate
            [self setSelectedAtIndex:toSeletion];
            _selectedIndex = toSeletion;
        }
    } else {
        CircleLayer *layer = (CircleLayer *)self.layer.sublayers[fromSeletion];
        if (layer) {
            if (layer.isSelected) {
                // delegate
                [self setDeselectedAtIndex:fromSeletion];
            } else {
                // delegate
                [self setSelectedAtIndex:fromSeletion];
            }
        }
    }
}

#pragma mark - touch handling

- (void)setSelectedAtIndex:(NSInteger)index {
    CircleLayer *layer = (CircleLayer *)self.layer.sublayers[index];
    if (!layer.isSelected) {
        CGPoint currPos = layer.position;
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        CGPoint newPos = CGPointMake(currPos.x + _selectedOffsetRadius*cos(middleAngle), currPos.y + _selectedOffsetRadius*sin(middleAngle));
        // 这里的位移会产生显式动画
        layer.position = newPos;
        layer.currentRadius = 0;
        layer.isSelected = YES;
    }
}

- (void)setDeselectedAtIndex:(NSInteger)index {
    CircleLayer *layer = (CircleLayer *)self.layer.sublayers[index];
    if (layer.isSelected) {
        layer.position = CGPointMake(0, 0);
        layer.currentRadius = _pieRadius;
        layer.isSelected = NO;
    }
}

- (NSInteger)getSelectedIndexOnTouch:(CGPoint)point {
    __block NSInteger index = -1;
    PolarCoordinate polar = decartToPolar(_pieCenter, point);
    
    CGFloat newRadius = _pieRadius + _selectedOffsetRadius;
    // 判断大半径
    if (polar.radius < newRadius-_pieWidth/2-_selectedOffsetRadius || polar.radius > newRadius+_pieWidth/2) {
        return index;
    }
    
    NSArray *pieLayers = self.layer.sublayers;
    [pieLayers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CircleLayer *layer = (CircleLayer *)obj;
        CGFloat currentStartAngle = [[layer.presentationLayer valueForKey:@"startAngle"] doubleValue];
        CGFloat currentEndAngle = [[layer.presentationLayer valueForKey:@"endAngle"] doubleValue];
        
        // 判断真实半径
        BOOL selectedSelect = layer.isSelected && (polar.radius > newRadius-_pieWidth/2 && polar.radius < newRadius+_pieWidth/2);
        BOOL deselectedSelect = !layer.isSelected && (polar.radius > _pieRadius-_pieWidth/2 && polar.radius < _pieRadius+_pieWidth/2);
        
        if (selectedSelect || deselectedSelect) {
            // 判断角度
            if (polar.angle > currentStartAngle && polar.angle < currentEndAngle) {
                index = idx;
            } else if (currentEndAngle > 2*M_PI) {
                CGFloat tempEnd = currentEndAngle - 2*M_PI;
                if (polar.angle >= 0 && polar.angle < tempEnd) {
                    index = idx;
                }
            }
        }
    }];
    
    return index;
}

@end
