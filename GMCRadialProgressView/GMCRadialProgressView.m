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

@interface GMCRadialProgressView ()

@property (nonatomic, strong) CALayer *colorLayer;
@property (nonatomic, strong) GMCRadialProgressLayer *maskLayer;
@property (nonatomic, strong) id inactiveContents;
@property (nonatomic, strong) id activeContents;

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
        
        self.state = GMCRadialProgressLayerStateInactive;
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

- (void)setState:(GMCRadialProgressViewState)state {
    [self setState:state animated:NO completion:nil];
}

- (void)setState:(GMCRadialProgressViewState)state animated:(BOOL)animated completion:(void (^)(void))completion {
    [CATransaction begin];
    
    if (animated) {
        if (completion) {
            [CATransaction setCompletionBlock:completion];
        }
    } else  {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    
    self.maskLayer.state = (GMCRadialProgressLayerState)state;
    
    self.colorLayer.contents = (self.state != GMCRadialProgressViewStateInactive ? self.activeContents : self.inactiveContents);
    
    [CATransaction commit];
}

- (GMCRadialProgressViewState)state {
    return (GMCRadialProgressViewState)self.maskLayer.state;
}

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO completion:nil];
}

- (void)setProgress:(float)progress animated:(BOOL)animated completion:(void (^)(void))completion {
    [CATransaction begin];
    
    if (animated) {
        if (completion) {
            [CATransaction setCompletionBlock:completion];
        }
    } else  {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    
    self.maskLayer.progress = progress;
    
    [CATransaction commit];
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
