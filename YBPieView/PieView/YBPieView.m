//
//  YBPieView.m
//  YBPieView
//
//  Created by 焦英博 on 2017/3/16.
//  Copyright © 2017年 焦英博. All rights reserved.
//

#import "YBPieView.h"
#import "CircleLayer.h"
#import "YBPieViewMath.h"
#import "RotateGestureRecognizer.h"

@interface YBPieView () {
    NSTimer *_animationTimer;
    NSMutableArray *_animations;
    CGPoint _pieCenter;
    CGFloat _pieRadius;
    NSInteger _selectedIndex;
}

@end

@implementation YBPieView

#pragma mark - view init

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _animations = [[NSMutableArray alloc] init];
        _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        _animationDuration = 3;
        _startPieAngle = 0;
        _pieLineWidth = 40;
        _pieRadius = MIN(frame.size.width/2 - _pieLineWidth, frame.size.width/2 - _pieLineWidth);
        _selectedIndex = -1;
        _selectedOffsetRadius = 7.0;
        
        RotateGestureRecognizer *rotateRec = [[RotateGestureRecognizer alloc] initWithTarget:self action:@selector(rotateRecognizer:)];
        rotateRec.innerRadius = _pieRadius - _pieLineWidth/2;
        rotateRec.outerRadius = _pieRadius + _pieLineWidth/2;
        [self addGestureRecognizer:rotateRec];
        
        UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognizer:)];
        [self addGestureRecognizer:tapRec];
    }
    return self;
}

- (void)reloadData {
    self.userInteractionEnabled = NO;
    [self loadDataWithAnimationDuration:_animationDuration completion:nil];
    [self doTaskAfter:_animationDuration task:^(YBPieView *view) {
        self.userInteractionEnabled = YES;
    }];
}

- (void)loadDataWithAnimationDuration:(CGFloat)duration completion:(void(^)(YBPieView *view))block {
    [self segmentsDeselect];
    
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
    [CATransaction setAnimationDuration:duration];
    
    BOOL isOnEnd = (self.layer.sublayers.count && (dataCount == 0 || dataSourceSum <= 0));
    if(isOnEnd) {
        for(CircleLayer *layer in self.layer.sublayers){
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
            layer = [self createCircleLayerAtIndex:index];
            [self.layer addSublayer:layer];
        } else {
            layer = (CircleLayer *)self.layer.sublayers[index];
        }
        layer.isSelected = NO;
        double angle = angleArray[index];
        lastEndAngle += angle;
        double startAngle = _startPieAngle + lastStartAngle;
        double endAngle = _startPieAngle + lastEndAngle;
        
        layer.lineWidth = _pieLineWidth;
        layer.value = dataSources[index];
        layer.percentage = dataSourceSum ? layer.value/dataSourceSum : 0;
        
        UIColor *color = [self pieChart:self colorForSliceAtIndex:index];
        layer.strokeColor = color.CGColor;
        layer.fillColor = [UIColor clearColor].CGColor;
        
        [self createAnimationWithKeyPath:@"startAngle" fromValue:@(_startPieAngle) toValue:@(startAngle) layer:layer];
        [self createAnimationWithKeyPath:@"endAngle" fromValue:@(_startPieAngle) toValue:@(endAngle) layer:layer];
        
        lastStartAngle = lastEndAngle;
    }
    
    [CATransaction commit];
    
    if (block) {
        [self doTaskAfter:duration task:^(YBPieView *view) {
            block(view);
        }];
    }
}

- (void)segmentsDeselect {
    _selectedIndex = -1;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CircleLayer *layer = (CircleLayer *)obj;
        if (layer.isSelected) {
            [self setDeselectedAtIndex:idx completion:nil];
        }
    }];
}

- (CircleLayer *)createCircleLayerAtIndex:(NSInteger)index {
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

- (UIColor *)pieChart:(YBPieView *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    UIColor *color = nil;
    if ([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)]) {
        color = [_dataSource pieChart:self colorForSliceAtIndex:index];
    }
    if (!color) {
        color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
    }
    return color;
}

#pragma mark - CAAnimation delegate and timer

- (void)animationDidStart:(CAAnimation *)anim {
    if (!_animationTimer) {
        static float timeInterval = 1.0/60.0;
        _animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
    }
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
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

// 单指旋转手势
- (void)rotateRecognizer:(RotateGestureRecognizer *)gesture {
    if (_selectedIndex >= 0) {
        [self setDeselectedAtIndex:_selectedIndex completion:nil];
    }
    // 临界点的值为6.x和-6.x(即从0到2*M_PI突变)
    if ((gesture.angleIncrement > M_PI) || (gesture.angleIncrement < -M_PI)) return;
    
    self.startPieAngle += gesture.angleIncrement;
    [self loadDataWithAnimationDuration:0.1 completion:nil];
}

- (void)tapRecognizer:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    if (self.userInteractionEnabled) {
        NSInteger index = [self getSelectedIndexOnTouch:point];
        if (index != -1) {
            [self notifyDelegateFrom:_selectedIndex to:index];
        }
    }
}

#pragma mark - notify delegate

- (void)notifyDelegateFrom:(NSInteger)fromSeletion to:(NSInteger)toSeletion {
    self.userInteractionEnabled = NO;
    if (fromSeletion != toSeletion) {
        if (fromSeletion != -1) {
            // delegate
            // 使用block回调是为了动画执行完之后再进行下一步
            // 1.收回
            [self setDeselectedAtIndex:fromSeletion completion:^(YBPieView *view) {
                // 2.旋转
                [view circleRotateAtIndex:toSeletion completion:^(YBPieView *view) {
                    if (toSeletion != -1) {
                        // delegate
                        // 3.展开
                        [view setSelectedAtIndex:toSeletion completion:^(YBPieView *view) {
                            view.userInteractionEnabled = YES;
                        }];
                    }
                }];
            }];
            return;
        }
        if (toSeletion != -1) {
            // delegate
            [self circleRotateAtIndex:toSeletion completion:^(YBPieView *view) {
                if (toSeletion != -1) {
                    // delegate
                    [view setSelectedAtIndex:toSeletion completion:^(YBPieView *view) {
                        view.userInteractionEnabled = YES;
                    }];
                }
            }];
        }
    } else {
        CircleLayer *layer = (CircleLayer *)self.layer.sublayers[fromSeletion];
        if (layer) {
            if (layer.isSelected) {
                // delegate
                [self setDeselectedAtIndex:fromSeletion completion:^(YBPieView *view) {
                    view.userInteractionEnabled = YES;
                }];
            } else {
                // delegate
                [self setSelectedAtIndex:toSeletion completion:^(YBPieView *view) {
                    view.userInteractionEnabled = YES;
                }];
            }
        }
    }
}

#pragma mark - touch handling

- (void)doTaskAfter:(CGFloat)after task:(void(^)(YBPieView *view))block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * 1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (block) {
            block(self);
        }
    });
}

- (void)circleRotateAtIndex:(NSInteger)index completion:(void(^)(YBPieView *view))block {
    CGFloat animationDuration = 0.5;
    CircleLayer *layer = (CircleLayer *)self.layer.sublayers[index];
    if (!layer.isSelected) {
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        // 一直逆时针转，_StartPieAngle是会小于0的，小于0了就给它加圈
        while (middleAngle < 0) {
            middleAngle += 2*M_PI;
        }
        while (middleAngle > 2*M_PI) {
            middleAngle -= 2*M_PI;
        }
        if (fabs(middleAngle - M_PI/2) < 0.2) {
            animationDuration = 0.1;
        }
        if (middleAngle > M_PI/2 && middleAngle < 3*M_PI/2) {
            _startPieAngle -= middleAngle - M_PI/2;
        } else if (middleAngle == 3*M_PI/2 || middleAngle == M_PI/2) {
            animationDuration = 0;
        } else if (middleAngle > 3*M_PI/2 && middleAngle <= 2*M_PI) {
            _startPieAngle += 2*M_PI - middleAngle + M_PI/2;
        } else if (middleAngle >= 0 && middleAngle < M_PI/2) {
            _startPieAngle += M_PI/2 - middleAngle;
        }
        [self loadDataWithAnimationDuration:animationDuration completion:nil];
    }
    if (block) {
        [self doTaskAfter:animationDuration task:^(YBPieView *view) {
            block(view);
        }];
    }
}

- (void)setSelectedAtIndex:(NSInteger)index completion:(void(^)(YBPieView *view))block {
    CircleLayer *layer = (CircleLayer *)self.layer.sublayers[index];
    if (!layer.isSelected) {
        CGPoint currPos = layer.position;
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        CGPoint newPos = CGPointMake(currPos.x + _selectedOffsetRadius*cos(middleAngle), currPos.y + _selectedOffsetRadius*sin(middleAngle));
        // 这里的位移会产生显式动画
        layer.position = newPos;
        layer.isSelected = YES;
        _selectedIndex = index;
    }
    if (block) {
        [self doTaskAfter:0.3 task:^(YBPieView *view) {
            block(view);
        }];
    }
}

- (void)setDeselectedAtIndex:(NSInteger)index completion:(void(^)(YBPieView *view))block {
    CircleLayer *layer = (CircleLayer *)self.layer.sublayers[index];
    if (layer.isSelected) {
        layer.position = CGPointMake(0, 0);
        layer.isSelected = NO;
        _selectedIndex = -1;
    }
    if (block) {
        [self doTaskAfter:0.3 task:^(YBPieView *view) {
            block(view);
        }];
    }
}

- (NSInteger)getSelectedIndexOnTouch:(CGPoint)point {
    __block NSInteger index = -1;
    PolarCoordinate polar = decartToPolar(_pieCenter, point);
    
    CGFloat newRadius = _pieRadius + _selectedOffsetRadius;
    // 判断大半径(半径+选中偏移量)
    if (polar.radius < newRadius-_pieLineWidth/2-_selectedOffsetRadius || polar.radius > newRadius+_pieLineWidth/2) {
        return index;
    }
    
    NSArray *pieLayers = self.layer.sublayers;
    [pieLayers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CircleLayer *layer = (CircleLayer *)obj;
        CGFloat currentStartAngle = [[layer.presentationLayer valueForKey:@"startAngle"] doubleValue];
        CGFloat currentEndAngle = [[layer.presentationLayer valueForKey:@"endAngle"] doubleValue];
        
        // 判断真实半径
        BOOL selectedSelect = layer.isSelected && (polar.radius > newRadius-_pieLineWidth/2 && polar.radius < newRadius+_pieLineWidth/2);
        BOOL deselectedSelect = !layer.isSelected && (polar.radius > _pieRadius-_pieLineWidth/2 && polar.radius < _pieRadius+_pieLineWidth/2);
        
        if (selectedSelect || deselectedSelect) {
            // 判断角度
            if (polar.angle > currentStartAngle && polar.angle < currentEndAngle) {
                index = idx;
            }
            
            NSInteger round = _startPieAngle/2*M_PI + 1;
            CGFloat angle = polar.angle;
            
            // 角度大于2π时，触摸点加圈判断，小于0时触摸点减圈判断
            if (round >= 1) {
                while (round) {
                    angle += 2*M_PI;
                    if (angle > currentStartAngle && angle < currentEndAngle) {
                        index = idx;
                        break;
                    }
                    round --;
                }
            } else {
                while (round) {
                    angle -= 2*M_PI;
                    if (angle > currentStartAngle && angle < currentEndAngle) {
                        index = idx;
                        break;
                    }
                    round ++;
                }
            }
        }
    }];
    return index;
}

@end
