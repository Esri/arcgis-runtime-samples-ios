/*
 WIPinnedView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIPinnedView.h"
#import <QuartzCore/QuartzCore.h>

#define kPushPinYOrigin (-25.0f)
#define kTapeYOrigin (-30.0f)

@interface WIPinnedView ()

@property (nonatomic, strong) UIImageView   *leftPinView;
@property (nonatomic, strong) UIImageView   *rightPinView;

- (void)setImageView:(UIImageView *)iv toType:(AGSPinnedViewType)type;

@end

@implementation WIPinnedView

@synthesize leftPinType     = _leftPinType;
@synthesize rightPinType    = _rightPinType;

@synthesize leftPinXOffset  = _leftPinXOffset;
@synthesize leftPinYOffset   = _leftPinYOffset;
@synthesize rightPinXOffset = _rightPinXOffset;
@synthesize rightPinYOffset = _rightPinYOffset;

@synthesize contentView     = _contentView;
@synthesize leftPinView     = _leftPinView;
@synthesize rightPinView    = _rightPinView;

@synthesize useShadow       = _useShadow;

- (void)dealloc
{
    self.contentView    = nil;
    
}

- (id)initWithContentView:(UIView *)cv leftPinType:(AGSPinnedViewType)leftPinType rightPinType:(AGSPinnedViewType)rightPinType
{
    self = [super initWithFrame:cv.frame];
    
    //Change the content view to fit flush in pinned view
    CGRect cvFrame = cv.frame;
    cvFrame.origin = CGPointZero;
    cv.frame = cvFrame;
    
    if(self)
    {
        UIImageView *liv = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.leftPinView = liv;
        
        UIImageView *riv = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.rightPinView = riv;
        
        [self addSubview:self.leftPinView];
        [self addSubview:self.rightPinView];
        
        self.contentView = cv;
        
        self.leftPinType = leftPinType;
        self.rightPinType = rightPinType;
        
        //default shadow is YES
        self.useShadow = YES;
        
        //Offsets
        self.leftPinXOffset = 0;
        self.leftPinYOffset = 0;
        self.rightPinXOffset = 0;
        self.rightPinYOffset = 0;
    }
    
    return self;
}

- (void)setLeftPinType:(AGSPinnedViewType)leftPinType
{
    //will automatically set size of image view
    [self setImageView:self.leftPinView toType:leftPinType];
    
    //need to adjust origin
    CGPoint newOrigin = CGPointMake(self.leftPinXOffset, self.leftPinYOffset);  //default for thumbtack
    switch (leftPinType) {
        case AGSPinnedViewTypePushPin:
            newOrigin = CGPointMake(-8 + self.leftPinXOffset, kPushPinYOrigin + self.leftPinYOffset);
            break;
        case AGSPinnedViewTypeTape:
            newOrigin = CGPointMake(-15 + self.leftPinXOffset, kTapeYOrigin + self.leftPinYOffset);
            break;
        default:
            break;
    }
    
    CGRect ivRect = self.leftPinView.frame;
    ivRect.origin = newOrigin;
    self.leftPinView.frame = ivRect;
    
    _leftPinType = leftPinType;
}

- (void)setRightPinType:(AGSPinnedViewType)rightPinType
{
    [self setImageView:self.rightPinView toType:rightPinType];
    
    //need to adjust origin
    CGRect ivRect = self.rightPinView.frame;
    CGPoint newOrigin = CGPointMake(self.frame.size.width - ivRect.size.width + self.rightPinXOffset, self.rightPinYOffset);
    switch (rightPinType) {
        case AGSPinnedViewTypePushPin:
            newOrigin = CGPointMake(self.frame.size.width - 40 + self.rightPinXOffset, kPushPinYOrigin + self.rightPinYOffset);
            break;
        case AGSPinnedViewTypeTape:
            newOrigin = CGPointMake(self.frame.size.width - 105+ self.rightPinXOffset , kTapeYOrigin + self.rightPinYOffset);
            break;
        default:
            break;
    }
    
    //make sure pin is placed in right spot
    ivRect.origin = newOrigin;
    self.rightPinView.frame = ivRect;
    
    _rightPinType = rightPinType;
}

- (void)setLeftPinXOffset:(CGFloat)leftPinXOffset
{
    _leftPinXOffset = leftPinXOffset;
    
    //force a redraw
    self.leftPinType = self.leftPinType;
}

- (void)setLeftPinYOffset:(CGFloat)leftPinYOffset
{
    _leftPinYOffset = leftPinYOffset;
    
    //force a redraw
    self.leftPinType = self.leftPinType;
}

- (void)setRightPinXOffset:(CGFloat)rightPinXOffset
{
    _rightPinXOffset = rightPinXOffset;
    
    //force a redraw
    self.rightPinType = self.rightPinType;
}

- (void)setRightPinYOffset:(CGFloat)rightPinYOffset
{
    _rightPinYOffset = rightPinYOffset;
    
    //force a redraw
    self.rightPinType = self.rightPinType;
}

- (void)setContentView:(UIView *)contentView
{
    if (_contentView){
		[_contentView removeFromSuperview];
	}
	
	
	_contentView = contentView;
	
    //below pins
    [self insertSubview:_contentView atIndex:0];
}

- (void)setUseShadow:(BOOL)useShadow
{
    if(useShadow)
    {
        //Shadow curl constants
        CGFloat curlFactor = 15.0f;
        CGFloat shadowDepth = 5.0f;
        
        //Shadow
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(5, 5);
        self.layer.shadowOpacity = 0.7f;
        
        CGSize size = self.bounds.size;
        UIBezierPath *shadowPath = [UIBezierPath bezierPath];
        [shadowPath moveToPoint:CGPointMake(0.0f, 0.0f)];
        [shadowPath addLineToPoint:CGPointMake(size.width, 0.0f)];
        [shadowPath addLineToPoint:CGPointMake(size.width, size.height + shadowDepth)];
        [shadowPath addCurveToPoint:CGPointMake(0.0f, size.height + shadowDepth)
                      controlPoint1:CGPointMake(size.width - curlFactor, size.height + shadowDepth - curlFactor)
                      controlPoint2:CGPointMake(curlFactor, size.height + shadowDepth - curlFactor)];
        self.layer.shadowPath = shadowPath.CGPath;
    }
    else 
    {
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowOpacity = 0.0f;
        self.layer.shadowPath = nil;
    }
    
    _useShadow = useShadow;
}

- (void)setImageView:(UIImageView *)iv toType:(AGSPinnedViewType)type
{
    CGRect ivRect = iv.frame;

    switch (type) {
        case AGSPinnedViewTypeNone:
            iv.image = nil;
            break;
        case AGSPinnedViewTypePushPin:
            iv.image = [UIImage imageNamed:@"Red_Push_Pin.png"];
            ivRect.size = CGSizeMake(60, 60);
            break;
        case AGSPinnedViewTypeThumbtack:
            iv.image = [UIImage imageNamed:@"a_tack.png"];
            ivRect.size = CGSizeMake(43, 43);
            break;
        case AGSPinnedViewTypeTape:
            iv.image = [UIImage imageNamed:@"masking_tape_small.png"];
            ivRect.size = CGSizeMake(120, 81);
        default:
            break;
    }
    
    iv.frame = ivRect;
}

@end
