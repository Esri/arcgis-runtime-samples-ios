/*
 WIListTitleView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIListTitleView.h"

@implementation WIListTitleView

@synthesize titleLabel  = _titleLabel;


- (id)initWithFrame:(CGRect)frame title:(NSString *)title
{
    self = [super initWithFrame:frame];
    if(self)
    {
        CGFloat margin = 5.0;
        CGRect labelRect = CGRectInset(self.bounds, margin, margin);
        
        labelRect.origin.y += 2*margin;
        labelRect.size.height -= 2*margin;
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.font = [UIFont fontWithName:@"Zapfino" size:36.0];
        label.backgroundColor = [UIColor whiteColor];
        label.textColor = [UIColor darkGrayColor];
        self.titleLabel = label;
        
        [self addSubview:self.titleLabel];
        
        self.titleLabel.text = title; 
    }
    
    return self;
}

@end
