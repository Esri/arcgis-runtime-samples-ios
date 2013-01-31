/*
 WIPinchableContainerView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIPinchableContainerView.h"
#import <QuartzCore/QuartzCore.h>

CGFloat slopeForLine(CGPoint start, CGPoint end) {
    return (end.y - start.y)/(end.x - start.x);
};

CGPoint yInterceptForLine(CGFloat slope, CGPoint point) {
    return CGPointMake(point.y - (slope*point.x), 0);
};

//
// the end scale for the views when animating out
CGFloat scaleForViewCount(int viewCount) {
    if (viewCount == 2) {
        return 0.8f;
    }
    else if (viewCount == 3) {
        return 0.7f;
    }
    else if (viewCount == 4) {
        return 0.6f;
    }
    else if (viewCount == 5) {
        return 0.45f;
    }
    else {
        return 0.0f;
    }
}


@interface WIPinchableContainerView () {
    int     _viewCount;
    BOOL    _animatedOut;    
}
@property (nonatomic, strong) NSMutableArray            *viewInfoArray;
@property (nonatomic, strong) UIPinchGestureRecognizer  *pinchGR;

- (void)updateSubviews;
- (CGPoint)endPointForSubviewAtIndex:(int)index;

@end

@implementation WIPinchableContainerView

@synthesize activeView      =   _activeView;
@synthesize pinchGR         =   _pinchGR;
@synthesize delegate        =   _delegate;
@synthesize viewInfoArray   =   _viewInfoArray;

- (void)dealloc {

    [self setDelegate:nil];
    [self.pinchGR setDelegate:nil];
    self.activeView = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinched)];
        self.pinchGR.delegate = self;
        [self addGestureRecognizer:self.pinchGR];
        
        self.viewInfoArray = [NSMutableArray array];
    }
    return self;
}


- (CGPoint)endPointForSubviewAtIndex:(int)index {
    int count = self.subviews.count;
    
    CGFloat halfH = (self.bounds.size.height / 2) - self.frame.origin.y;
    CGFloat halfW = (1024/2) - self.frame.origin.x;
    CGFloat fifthW = (1024/5) - self.frame.origin.x;
    
    //
    // if we have 2 views to animate out
    if (count == 2) {
        if (index == 0) {
            return CGPointMake(halfW*.5, halfH);
        }
        if (index == 1) {
            return CGPointMake(halfW*1.5, halfH);
        }
    }
    
    //
    // if we have 3 views to animate out
    if (count == 3) {
        if (index == 0) {
            return CGPointMake(halfW*1.5, halfH);
        }
        if (index == 1) {
            return CGPointMake(halfW, halfH);
        }
        if (index == 2) {
            return CGPointMake(halfW/2, halfH);
        }
    }

    if (count == 4) {
        if (index == 0) {
            return CGPointMake(fifthW, halfH);
        }
        if (index == 1) {
            return CGPointMake(2*fifthW, halfH);
        }
        if (index == 2) {
            return CGPointMake(3*fifthW, halfH);
        }
        if (index == 3) {
            return CGPointMake(4*fifthW, halfH);
        }
    }
    
    if (count == 5) 
    {
        if (index == 0) {
            return CGPointMake(halfW, halfH);
        }
        if (index == 1) {
            return CGPointMake(halfW*1.5, halfH*1.5);
        }
        if (index == 2) {
            return CGPointMake(halfW/2, halfH*1.5);
        }
        if (index == 3) {
            return CGPointMake(halfW/2, halfH/2);
        }
        if (index == 4) {
            return CGPointMake(halfW*1.5, halfH/2);
        }
    }
    
    return CGPointZero;
}

- (void)pinched {
    int i = 0;
    CGFloat s;
    switch (self.pinchGR.state) {
        case UIGestureRecognizerStateBegan:
            //
            // setup state
            
            [self.viewInfoArray removeAllObjects];
            
            for (UIView *v in self.subviews) {
                CGPoint endPoint = [self endPointForSubviewAtIndex:i];
                CGFloat slope = slopeForLine(v.center, endPoint);
                CGPoint yInt = yInterceptForLine(slope, v.center);
                NSArray *arr = [NSArray arrayWithObjects:
                                [NSValue valueWithCGPoint:v.center],    //start point
                                [NSValue valueWithCGPoint:endPoint],    //end point
                                [NSNumber numberWithFloat:slope],       // slope
                                [NSValue valueWithCGPoint:yInt],        // yInt
                                nil];
                [self.viewInfoArray addObject:arr];
                i++;
            }
            break;
        case UIGestureRecognizerStateChanged:

            s = self.pinchGR.scale - 1.0f;
            if (1.0 >= s  && s > 0.0) {
                //NSLog(@"pinched: %f", s);                
                [self.delegate pinchView:self pinchingWithScale:self.pinchGR.scale];
                
                CGFloat scale = scaleForViewCount(self.subviews.count);
                
                for (UIView *v in self.subviews) {
                    NSArray *a = [self.viewInfoArray objectAtIndex:i];
                    CGPoint endPoint = [[a objectAtIndex:1] CGPointValue];
                    CGPoint startPoint = [[a objectAtIndex:0] CGPointValue];
                    CGFloat x = (endPoint.x - startPoint.x) * s;
                    CGFloat y = (endPoint.y - startPoint.y) * s;                
                    CGAffineTransform t1 = CGAffineTransformMakeTranslation(x, y);
                    
                    // s is adjusted scale based on getting from 1 to .5... 1 - s * (1-.5)
                    CGAffineTransform t2 = CGAffineTransformMakeScale(1 - s * (1-scale), 1 - s * (1-scale));                    
                    v.transform = CGAffineTransformConcat(t2, t1);
                    
                    i++;
                }
            }
            
            break;
        case UIGestureRecognizerStateEnded:
            //
            // tear down state            
            //
            // if we have passed our threshold, leave the animated view in place
            if ((self.pinchGR.scale - 1.0f) > .5f) {
                [self animateOut];
            }
            else {
                [self animateBack];
            }
            
            break;
        default:
            break;
    }
}

// called when a gesture recognizer attempts to transition out of UIGestureRecognizerStatePossible. returning NO causes it to transition to UIGestureRecognizerStateFailed
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return (self.subviews.count > 1);
}

- (void)updateSubviews {
    _animatedOut = NO;
    int i = 0;
    NSArray *subViews = self.subviews;
    _viewCount = subViews.count;
    for (UIView *v in subViews.reverseObjectEnumerator) {
        CGFloat degrees = 1.0f * i;
        BOOL negative = subViews.count % 2 == 0;
        if (negative) {
            degrees *= -1;
        }
        v.layer.borderWidth = 1.0f;
        v.layer.borderColor = [[UIColor blackColor] CGColor];
        v.transform = CGAffineTransformMakeRotation(degrees*(M_PI*2)/360);
        i++;
    }
}

- (void)addListView:(UIView*)listView {
    [self addSubview:listView];
    [self updateSubviews];
}

- (void)removeListView:(UIView*)listView {
    [listView removeFromSuperview];
    [self updateSubviews];    
}

- (void)animateBack { 
    [self.delegate pinchViewWillAnimateBack:self];
    [UIView animateWithDuration:0.5f animations:^{
        [self updateSubviews];
    }completion:^(BOOL completed)
     {
         [self.delegate pinchViewDidAnimateBack:self];
     }
     ];
}

- (void)animateOut {
    [UIView animateWithDuration:0.25f animations:^{
        int i = 0;
        CGFloat scale = scaleForViewCount(self.subviews.count);
        for (UIView *v in self.subviews) {
            NSArray *a = [self.viewInfoArray objectAtIndex:i];
            CGPoint endPoint = [[a objectAtIndex:1] CGPointValue];
            CGPoint currPoint = v.center;
            CGFloat x = (endPoint.x - currPoint.x);
            CGFloat y = (endPoint.y - currPoint.y);                
            CGAffineTransform t1 = CGAffineTransformMakeTranslation(x, y);
            CGAffineTransform t2 = CGAffineTransformMakeScale(scale, scale);
            v.transform = CGAffineTransformConcat(t2, t1);            
            i++;
        }       
        _animatedOut = YES;
    }completion:^(BOOL completed)
     {
         [self.delegate pinchViewDidAnimateOut:self];
     }
     ];
}

//
// when our views are animated out, they will not be able to trigger
// the gesture recognizer because they are beyond their parent's bounds
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [super pointInside:point withEvent:event] || _animatedOut;
}

@end


