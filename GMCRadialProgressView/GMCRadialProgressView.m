// GMCRadialProgressView.m
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

#import "GMCRadialProgressView.h"
#import "GMCRadialProgressLayer.h"

@interface GMCRadialProgressViewTransition : NSObject

@property (nonatomic, assign) GMCRadialProgressLayerState state;
@property (nonatomic, assign) float progress;
@property (nonatomic, copy) void (^completionBlock)(void);

+ (instancetype)transitionWithState:(GMCRadialProgressLayerState)state progress:(float)progress completion:(void (^)(void))completion;

@end

@implementation GMCRadialProgressViewTransition

+ (instancetype)transitionWithState:(GMCRadialProgressLayerState)state progress:(float)progress completion:(void (^)(void))completion {
    GMCRadialProgressViewTransition *transition = [[GMCRadialProgressViewTransition alloc] init];
    transition.state = state;
    
    switch (transition.state) {
        case GMCRadialProgressLayerStateInactive:
            transition.progress = progress;
            break;
        case GMCRadialProgressLayerStateActive:
            transition.progress = 0;
            break;
        case GMCRadialProgressLayerStateInProgress:
            transition.progress = progress;
            break;
        case GMCRadialProgressLayerStateComplete:
            transition.progress = 1;
            break;
    }
    
    transition.completionBlock = completion;
    
    return transition;
}

@end

@interface GMCRadialProgressView ()

@property (nonatomic, strong) CALayer *colorLayer;
@property (nonatomic, strong) GMCRadialProgressLayer *maskLayer;
@property (nonatomic, strong) id inactiveContents;
@property (nonatomic, strong) id activeContents;

@property (nonatomic, strong) NSMutableArray *queuedTransitions;

@end

@implementation GMCRadialProgressView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.inactiveColor = [UIColor colorWithWhite:1 alpha:0.9f];
        self.activeColor = [UIColor colorWithWhite:0 alpha:0.7f];
        
        self.colorLayer = ({
            CALayer *colorLayer = [[CALayer alloc] init];
            [self.layer addSublayer:colorLayer];
            colorLayer;
        });
        
        self.maskLayer = ({
            GMCRadialProgressLayer *maskLayer = [[GMCRadialProgressLayer alloc] init];
            maskLayer.contentsScale = [UIScreen mainScreen].scale;
            maskLayer.opaque = NO;
            self.colorLayer.mask = maskLayer;
            maskLayer;
        });
        
        self.queuedTransitions = [NSMutableArray array];
        
        [self setState:GMCRadialProgressViewStateInactive progress:0 animated:NO completion:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    self.colorLayer.frame = self.bounds;
    self.maskLayer.frame = self.bounds;
    
    [CATransaction commit];
}

- (void)setInactiveColor:(UIColor *)inactiveColor {
    _inactiveColor = inactiveColor;
    
    self.inactiveContents = [self layerContentsWithColor:self.inactiveColor];
}

- (void)setActiveColor:(UIColor *)activeColor {
    _activeColor = activeColor;
    
    self.activeContents = [self layerContentsWithColor:self.activeColor];
}

- (void)setRadiusRatio:(float)radiusRatio {
    self.maskLayer.radiusRatio = radiusRatio;
}

- (float)radiusRatio {
    return self.maskLayer.radiusRatio;
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    self.maskLayer.strokeWidth = strokeWidth;
}

- (CGFloat)strokeWidth {
    return self.maskLayer.strokeWidth;
}

- (void)setState:(GMCRadialProgressViewState)state progress:(float)progress animated:(BOOL)animated completion:(void (^)(void))completion {
    BOOL performNextTransition = NO;
    if (!animated) {
        [self.queuedTransitions removeAllObjects];
    }
    if ([self.queuedTransitions count] == 0) {
        performNextTransition = YES;
    }
    
    GMCRadialProgressViewTransition *transition = [GMCRadialProgressViewTransition transitionWithState:(GMCRadialProgressLayerState)state progress:progress completion:completion];
    [self.queuedTransitions addObject:transition];
    [self massageQueuedTransitions];
    
    if (performNextTransition) {
        [self performNextTransitionAnimated:animated];
    }
}

- (void)massageQueuedTransitions {
    if ([self.queuedTransitions count] > 0) {
        GMCRadialProgressViewTransition *transition1 = self.queuedTransitions[[self.queuedTransitions count] - 1];
        
        if ([self.queuedTransitions count] > 1) {
            GMCRadialProgressViewTransition *transition2 = self.queuedTransitions[[self.queuedTransitions count] - 2];
            
            if (transition1.state == GMCRadialProgressLayerStateInProgress &&
                transition2.state == GMCRadialProgressLayerStateInProgress &&
                (transition1.progress == transition2.progress || transition2.progress != 0)) {
                [self.queuedTransitions removeObject:transition2];
            }
        }
    
        if (transition1.state == GMCRadialProgressLayerStateInProgress) {
            if ([self.queuedTransitions count] > 1) {
                GMCRadialProgressViewTransition *transition2 = self.queuedTransitions[[self.queuedTransitions count] - 2];
                
                if (transition2.state == GMCRadialProgressViewStateInactive) {
                    GMCRadialProgressViewTransition *transition2 = [GMCRadialProgressViewTransition transitionWithState:GMCRadialProgressLayerStateActive progress:0 completion:nil];
                    [self.queuedTransitions insertObject:transition2 atIndex:[self.queuedTransitions count] - 1];
                }
            } else {
                if (self.state == GMCRadialProgressViewStateInactive) {
                    GMCRadialProgressViewTransition *transition2 = [GMCRadialProgressViewTransition transitionWithState:GMCRadialProgressLayerStateActive progress:0 completion:nil];
                    [self.queuedTransitions insertObject:transition2 atIndex:[self.queuedTransitions count] - 1];
                }
            }
        }
        
        if (transition1.state == GMCRadialProgressLayerStateComplete) {
            if ([self.queuedTransitions count] > 1) {
                GMCRadialProgressViewTransition *transition2 = self.queuedTransitions[[self.queuedTransitions count] - 2];
                
                if (transition2.state == GMCRadialProgressViewStateInProgress) {
                    if (transition2.progress == 0) {
                        GMCRadialProgressViewTransition *transition3 = [GMCRadialProgressViewTransition transitionWithState:GMCRadialProgressLayerStateInProgress progress:1 completion:nil];
                        [self.queuedTransitions insertObject:transition3 atIndex:[self.queuedTransitions count] - 1];
                    } else {
                        transition2.progress = 1;
                    }
                }
            } else {
                if (self.state == GMCRadialProgressViewStateInProgress) {
                    GMCRadialProgressViewTransition *transition2 = [GMCRadialProgressViewTransition transitionWithState:GMCRadialProgressLayerStateInProgress progress:1 completion:nil];
                    [self.queuedTransitions insertObject:transition2 atIndex:[self.queuedTransitions count] - 1];
                }
            }
        }
    }
}

- (void)performTransition:(GMCRadialProgressViewTransition *)transition animated:(BOOL)animated {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (transition.completionBlock) {
            transition.completionBlock();
        }
        
        [self.queuedTransitions removeObject:transition];
        [self performNextTransitionAnimated:YES];
    }];
    
    if (animated) {
        [CATransaction setAnimationDuration:0.3];
    } else {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    
    self.maskLayer.state = transition.state;
    self.maskLayer.progress = transition.progress;
    
    self.colorLayer.contents = (self.state != GMCRadialProgressViewStateInactive ? self.activeContents : self.inactiveContents);
    
    [CATransaction commit];
}

- (void)performNextTransitionAnimated:(BOOL)animated {
    GMCRadialProgressViewTransition *nextTransition = [self.queuedTransitions firstObject];
    if (nextTransition) {
        [self performTransition:nextTransition animated:animated];
    }
}

- (GMCRadialProgressViewState)state {
    return (GMCRadialProgressViewState)self.maskLayer.state;
}

- (float)progress {
    return self.maskLayer.progress;
}

- (id)layerContentsWithColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
    
    [color setFill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return (id)image.CGImage;
}

@end
