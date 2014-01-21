// GMCRadialProgressLayer.m
//
// Copyright (c) 2014 Hilton Campbell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GMCRadialProgressLayer.h"

@interface GMCRadialProgressLayer ()

@property (nonatomic, assign) CGFloat outerRadius;
@property (nonatomic, assign) CGFloat innerRadius;

@end

@implementation GMCRadialProgressLayer

@dynamic progress;
@dynamic outerRadius;
@dynamic innerRadius;

- (id)init {
    if ((self = [self initWithLayer:nil])) {
    }
    return self;
}

- (id)initWithLayer:(id)layer {
    if ((self = [super initWithLayer:layer])) {
        _radiusRatio = 0.5f;
        _strokeWidth = 3;
        
        if ([layer isKindOfClass:[GMCRadialProgressLayer class]]) {
            GMCRadialProgressLayer *other = (GMCRadialProgressLayer *)layer;
            self.state = other.state;
            self.progress = other.progress;
            self.outerRadius = other.outerRadius;
            self.innerRadius = other.innerRadius;
            self.radiusRatio = other.radiusRatio;
            self.strokeWidth = other.strokeWidth;
        }
    }
    return self;
}

- (void)setState:(GMCRadialProgressLayerState)state {
    _state = state;
    
    [self updateState];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [self updateState];
    [CATransaction commit];
    
    [self setNeedsDisplay];
}

- (void)updateState {
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    switch (self.state) {
        case GMCRadialProgressLayerStateInactive:
        case GMCRadialProgressLayerStateActive:
            self.outerRadius = 0;
            self.innerRadius = 0;
            break;
        case GMCRadialProgressLayerStateInProgress:
            self.outerRadius = roundf(MIN(center.x, center.y) * self.radiusRatio);
            self.innerRadius = roundf(MIN(center.x, center.y) * self.radiusRatio) - self.strokeWidth;
            break;
        case GMCRadialProgressLayerStateComplete:
            self.outerRadius = ceilf(sqrtf(center.x * center.x + center.y * center.y));
            self.innerRadius = roundf(MIN(center.x, center.y) * self.radiusRatio) - self.strokeWidth;
            break;
    }
}

- (void)drawInContext:(CGContextRef)context {
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    
    if (self.outerRadius > 0) {
        CGFloat startAngle = 2 * M_PI * self.progress - M_PI_2;
        CGFloat endAngle = M_PI_2 * 3;
        
        CGFloat trueInnerRadius = MAX(0, MIN(self.innerRadius, self.outerRadius - self.strokeWidth));
        
        CGPoint firstPointOnArc = CGPointMake(center.x + trueInnerRadius * cosf(startAngle), center.y + trueInnerRadius * sinf(startAngle));
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddLineToPoint(context, firstPointOnArc.x, firstPointOnArc.y);
        CGContextAddArc(context, center.x, center.y, trueInnerRadius, startAngle, endAngle, 0);
        CGContextClosePath(context);
        
        CGContextFillPath(context);
    }

    CGContextAddRect(context, self.bounds);
    
    if (self.outerRadius > 0) {
        CGContextAddEllipseInRect(context, CGRectMake(center.x - self.outerRadius, center.y - self.outerRadius, 2 * self.outerRadius, 2 * self.outerRadius));
    }
    
    CGContextEOFillPath(context);
}

- (id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"contents"]) {
        return nil;
    }
    if ([event isEqualToString:@"progress"] || [event isEqualToString:@"outerRadius"] || [event isEqualToString:@"innerRadius"]) {
        return [self makeAnimationForKey:event];
    }
    
    return [super actionForKey:event];
}

- (CABasicAnimation *)makeAnimationForKey:(NSString *)key {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
    animation.fromValue = [[self presentationLayer] valueForKey:key];
    animation.duration = 0.3;
    return animation;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"progress"] || [key isEqualToString:@"outerRadius"] || [key isEqualToString:@"innerRadius"]) {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

@end
