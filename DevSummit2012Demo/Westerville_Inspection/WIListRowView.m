/*
 WIListRowView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIListRowView.h"

@implementation WIListRowView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(currentContext);
    
    CGContextSetLineWidth(currentContext, 3);
    
    CGContextSetStrokeColorWithColor(currentContext, [[UIColor lightGrayColor] CGColor]);
    
    CGFloat margin = 20.0f;
    
    //stroke the bottom of the view.
    CGContextBeginPath(currentContext);
    CGContextMoveToPoint(currentContext, margin, rect.size.height);
    CGContextAddLineToPoint(currentContext, rect.size.width - margin, rect.size.height);
    CGContextStrokePath(currentContext);
    CGContextRestoreGState(currentContext);
}

@end
