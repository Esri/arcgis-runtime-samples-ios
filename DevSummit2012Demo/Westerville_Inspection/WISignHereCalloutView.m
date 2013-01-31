/*
 WISignHereCalloutView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WISignHereCalloutView.h"
#import <ArcGIS/ArcGIS.h>

@implementation WISignHereCalloutView

- (id)initWithGraphic:(AGSGraphic *)graphic
{
    CGFloat kCalloutWidth = 160.0f;
    CGFloat kCalloutHeight = 82.0f;
    
    self = [super initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight) withGraphic:graphic];
    if(self)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"callout_sticker.png"]];
        
        CGFloat margin = 6.0f;
        CGFloat buttonWidth = 32.0f;
        
        self.addStopButton.frame = CGRectMake(margin, margin, buttonWidth, buttonWidth);
        self.moreInfoButton.frame = CGRectMake(margin, 2*margin + buttonWidth, buttonWidth, buttonWidth);        
        
        [self addSubview:self.addStopButton];
        [self addSubview:self.moreInfoButton];  
    }
    
    return self;
}

@end
