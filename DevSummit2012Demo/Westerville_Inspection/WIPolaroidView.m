/*
 WIPolaroidView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIPolaroidView.h"

#define kPolaroidDevelopmentTime 3

@interface WIPolaroidView () 

/* Our white, polaroid background */
@property (nonatomic, strong) UIImageView *backgroundView;

/* view that houses the actual image to be displayed */
@property (nonatomic, strong) UIImageView *polaroidContentView;

@end

@implementation WIPolaroidView

@synthesize backgroundView      = _backgroundView;
@synthesize polaroidContentView = _polaroidContentView;


- (id)initWithOrigin:(CGPoint)origin withImage:(UIImage *)image
{
    CGFloat polaroidBackgroundHeight    = 383.0f;
    CGFloat polaroidBackgroundWidth     = 350.0f;
        
    // load our "polaroid" background image
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"polaroid.png"]];
    iv.frame = CGRectMake(origin.x, origin.y, polaroidBackgroundWidth, polaroidBackgroundHeight);
    self.backgroundView = iv;
    
    self = [super initWithContentView:self.backgroundView 
                    leftPinType:AGSPinnedViewTypePushPin  
                   rightPinType:AGSPinnedViewTypeNone];
    if(self)
    {
        self.leftPinXOffset = self.frame.size.width/2 - 30.0;
        self.leftPinYOffset = -15.0f;
        
        UIImageView *contentImage = [[UIImageView alloc] initWithImage:image];
        contentImage.frame = CGRectMake(24, 23, 304, 277);
        contentImage.hidden = YES;
        contentImage.alpha = 0.0;
        self.polaroidContentView = contentImage;
        
        [self.backgroundView addSubview:self.polaroidContentView];
    }
    
    return self;
}

/* If animated, will cause the image to "appear" after the specified time */
- (void)processPolaroidAnimated:(BOOL)animated;
{
    self.polaroidContentView.hidden = NO;
    
    CGFloat animationTime = animated ? (kPolaroidDevelopmentTime) : 0.0f;
    [UIView animateWithDuration:animationTime animations:^
     {
         self.polaroidContentView.alpha = 1.0;
     }
     ];
}

@end
