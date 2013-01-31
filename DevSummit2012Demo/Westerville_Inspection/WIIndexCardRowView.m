/*
 WIIndexCardRowView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIIndexCardRowView.h"

@implementation WIIndexCardRowView

@synthesize isTitleRow = _isTitleRow;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame isTitleRow:NO];
}

- (id)initWithFrame:(CGRect)frame isTitleRow:(BOOL)titleRow
{
    self = [super initWithFrame:frame];
    if (self) {
        _isTitleRow = titleRow;
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setIsTitleRow:(BOOL)isTitleRow
{
    if(_isTitleRow == isTitleRow)
    {
        return;
    }
    
    _isTitleRow = isTitleRow;
    
    [self setNeedsDisplay];
}

- (UIColor *)lineColor
{
    //if its a title row, the color is a purple-red color.  Otherwise its a teal-blue color.
    return self.isTitleRow ? [UIColor colorWithRed:(131.0/255.0) green:(80.0/255.0) blue:(95.0/255.0) alpha:1.0] : [UIColor colorWithRed:(180.0/255.0) green:(210.0/255.0) blue:(210.0/255.0) alpha:1.0];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(currentContext);
    
    
    //Title row line is slightly thicker
    CGContextSetLineWidth(currentContext, _isTitleRow ? 9 : 6);
    
    CGContextSetStrokeColorWithColor(currentContext, [[self lineColor] CGColor]);
    
    //stroke the bottom of the view.
    CGContextBeginPath(currentContext);
    CGContextMoveToPoint(currentContext, 0, rect.size.height);
    CGContextAddLineToPoint(currentContext, rect.size.width, rect.size.height);
    CGContextStrokePath(currentContext);
    CGContextRestoreGState(currentContext);
}

@end
