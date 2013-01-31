/*
 WIListTableViewCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIListTableViewCell.h"
#import "WIListRowView.h"

@implementation WIListTableViewCell

@synthesize rowView = _rowView;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self)
    {
        CGRect myFrame = self.frame;
        myFrame.size.height = 44.0;
        self.frame = myFrame;
        
        WIListRowView *rv = [[WIListRowView alloc] initWithFrame:self.frame];
        rv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.rowView = rv;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.rowView];
    }
    
    return self;
}

@end
