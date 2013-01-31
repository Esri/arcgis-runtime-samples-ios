/*
 WISignatureLineView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WISignatureLineView.h"

#define kBottomLineMargin (40.0f)
#define kXLabelHeight (50.0f)

@implementation WISignatureLineView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UILabel *xLabel = [[UILabel alloc] initWithFrame:self.xRect];
        xLabel.text = @"X";
        xLabel.font = [UIFont fontWithName:@"MarkerFelt-Wide" size:45.0];
        xLabel.backgroundColor = [UIColor clearColor];
        xLabel.textColor = [UIColor blackColor];
        
        [self addSubview:xLabel];
    }
    return self;
}

- (CGRect)xRect
{
    return CGRectMake(5, self.frame.size.height - (kBottomLineMargin + kXLabelHeight), kXLabelHeight, kXLabelHeight);
}

- (void)drawRect:(CGRect)rect
{
    // get the current graphics context
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(currentContext);
    
    // setup some properties of the line
    CGContextSetLineWidth(currentContext, 2);    
    CGContextSetStrokeColorWithColor(currentContext, [[UIColor blackColor] CGColor]);
    
    //stroke the bottom of the view.
    CGContextBeginPath(currentContext);
    CGContextMoveToPoint(currentContext, 0, rect.size.height - kBottomLineMargin);
    CGContextAddLineToPoint(currentContext, rect.size.width, rect.size.height - kBottomLineMargin);
    CGContextStrokePath(currentContext);
    CGContextRestoreGState(currentContext);
}

@end
