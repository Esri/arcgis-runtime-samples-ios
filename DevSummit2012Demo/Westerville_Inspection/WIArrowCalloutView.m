/*
 WIArrowCalloutView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIArrowCalloutView.h"

@implementation WIArrowCalloutView

- (id)initWithGraphic:(AGSGraphic *)graphic
{
    CGFloat kCalloutWidth = 147.0f;
    CGFloat kCalloutHeight = 100.0f;
    
    self = [super initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight) withGraphic:graphic];
    if(self)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"black-arrow.png"]];
        
        CGFloat topMargin = 35.0f;
        CGFloat spaceBetweenButtons = 10.0f;
        CGFloat buttonWidth = 32.0f;
        
        self.addStopButton.frame = CGRectMake(spaceBetweenButtons, topMargin, buttonWidth, buttonWidth);
        self.moreInfoButton.frame = CGRectMake(buttonWidth + (2*spaceBetweenButtons), topMargin, buttonWidth, buttonWidth);        
        
        [self addSubview:self.addStopButton];
        [self addSubview:self.moreInfoButton];  
    }
    
    return self;
}

@end
