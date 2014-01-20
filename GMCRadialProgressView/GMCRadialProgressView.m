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

@property (nonatomic, strong) GMCRadialProgressLayer *maskLayer;
@property (nonatomic, assign) BOOL active;

@end

@implementation GMCRadialProgressView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.inactiveColor = [UIColor colorWithWhite:1 alpha:0.9f];
        self.activeColor = [UIColor colorWithWhite:0 alpha:0.7f];
        
        self.maskLayer = ({
            GMCRadialProgressLayer *maskLayer = [[GMCRadialProgressLayer alloc] init];
            maskLayer.contentsScale = [UIScreen mainScreen].scale;
            maskLayer.opaque = NO;
            self.layer.mask = maskLayer;
            maskLayer;
        });
        
        self.state = GMCRadialProgressLayerStateInactive;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.maskLayer.frame = self.bounds;
}

- (void)setState:(GMCRadialProgressViewState)state {
    [self setState:state animated:NO completion:nil];
}

- (void)setState:(GMCRadialProgressViewState)state animated:(BOOL)animated completion:(void (^)(void))completion {
    if (animated && state == GMCRadialProgressViewStateInProgress && !self.active && ![self.inactiveColor isEqual:self.activeColor]) {
        self.active = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.layer.backgroundColor = self.activeColor.CGColor;
        } completion:^(BOOL finished) {
            [self setState:state animated:YES completion:completion];
        }];
    } else {
        [CATransaction begin];
        
        if (animated) {
            if (completion) {
                [CATransaction setCompletionBlock:completion];
            }
        } else  {
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        }
        
        self.maskLayer.state = (GMCRadialProgressLayerState)state;
        
        switch (self.state) {
            case GMCRadialProgressViewStateInactive:
                self.active = NO;
                break;
            case GMCRadialProgressViewStateInProgress:
            case GMCRadialProgressViewStateComplete:
                self.active = YES;
                break;
        }
        
        self.layer.backgroundColor = (self.active ? self.activeColor.CGColor : self.inactiveColor.CGColor);
        
        [CATransaction commit];
    }
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

@end
