/*
 WIWaitingView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIWaitingView.h"
#import <QuartzCore/QuartzCore.h>

@interface WIWaitingView () 

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation WIWaitingView

@synthesize messageLabel    = _messageLabel;
@synthesize indicator       = _indicator;


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame message:nil];
}

- (id)initWithFrame:(CGRect)frame message:(NSString *)message
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
        self.layer.cornerRadius = 12.0f;
        
        CGFloat margin = 10.f;
        CGFloat fontHeight = 30.0f;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(margin, frame.size.height - (2*margin + fontHeight), frame.size.width - (2*margin), fontHeight + margin)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:fontHeight];
        label.textAlignment = UITextAlignmentCenter;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        label.text = message;
        self.messageLabel = label;
        
        UIActivityIndicatorView *iv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGFloat activityIndicatorWidth = 37.0f;
        iv.frame = CGRectMake(frame.size.width/2 - activityIndicatorWidth/2, frame.size.height/2 - activityIndicatorWidth/2, activityIndicatorWidth, activityIndicatorWidth);
        
        self.indicator = iv;
        [self.indicator startAnimating];
        
        [self addSubview:self.messageLabel];
        [self addSubview:self.indicator];
    }
    
    return self;
}

@end
