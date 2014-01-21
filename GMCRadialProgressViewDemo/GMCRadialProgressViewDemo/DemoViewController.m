// DemoViewController.m
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

#import "DemoViewController.h"
#import "GMCRadialProgressView.h"

@interface DemoViewController ()

@property (nonatomic, strong) UIView *itemView;
@property (nonatomic, strong) GMCRadialProgressView *radialProgressView;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation DemoViewController

- (void)dealloc {
    [self.timer invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.itemView = ({
        UIView *itemView = [[UIView alloc] init];
        itemView.backgroundColor = [UIColor redColor];
        itemView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:itemView];
        itemView;
    });
    
    self.radialProgressView = ({
        GMCRadialProgressView *radialProgressView = [[GMCRadialProgressView alloc] init];
        radialProgressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.itemView addSubview:radialProgressView];
        radialProgressView;
    });
    
    NSDictionary *views = @{ @"itemView": self.itemView, @"radialProgressView": self.radialProgressView };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-100-[itemView]-100-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[itemView]-100-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[radialProgressView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[radialProgressView]|" options:0 metrics:nil views:views]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

#pragma mark - Gesture recognizers

- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        switch (self.radialProgressView.state) {
            case GMCRadialProgressViewStateInactive:
                [self.radialProgressView setState:GMCRadialProgressViewStateInProgress progress:0 animated:YES completion:nil];
                break;
            case GMCRadialProgressViewStateInProgress: {
                __weak GMCRadialProgressView *radialProgressView = self.radialProgressView;
                [self.radialProgressView setState:GMCRadialProgressViewStateInactive progress:self.radialProgressView.progress animated:YES completion:^{
                    [radialProgressView setState:GMCRadialProgressViewStateInactive progress:0 animated:NO completion:nil];
                }];
                break;
            }
            case GMCRadialProgressViewStateComplete: {
                __weak GMCRadialProgressView *radialProgressView = self.radialProgressView;
                [self.radialProgressView setState:GMCRadialProgressViewStateInactive progress:self.radialProgressView.progress animated:YES completion:^{
                    [radialProgressView setState:GMCRadialProgressViewStateInactive progress:0 animated:NO completion:nil];
                }];
                break;
            }
        }
    }
}

#pragma mark - Timer

- (void)timerFired:(NSTimer *)timer {
    if (self.radialProgressView.state == GMCRadialProgressViewStateInProgress) {
        float progress = MIN(self.radialProgressView.progress + (arc4random_uniform(3) / (float)10), 1);
        [self.radialProgressView setState:GMCRadialProgressViewStateInProgress progress:progress animated:YES completion:nil];
        
        if (progress >= 1) {
            [self.radialProgressView setState:GMCRadialProgressViewStateComplete progress:1 animated:YES completion:nil];
        }
    }
}

@end
