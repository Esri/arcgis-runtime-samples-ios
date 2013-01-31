/*
 WIListTitleViewCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIListTitleViewCell.h"
#import "WIListTitleView.h"

@interface WIListTitleViewCell ()

@property (nonatomic, strong) WIListTitleView *titleView;

@end

@implementation WIListTitleViewCell

@synthesize titleView = _titleView;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier withTitle:(NSString *)title
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self)
    {
        CGRect myFrame = self.frame;
        myFrame.size.height = 88.0;
        self.frame = myFrame;  
        
        WIListTitleView *ltv = [[WIListTitleView alloc] initWithFrame:self.frame title:title];
        self.titleView = ltv;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.titleView];
    }
    
    return self;
    
}

@end
