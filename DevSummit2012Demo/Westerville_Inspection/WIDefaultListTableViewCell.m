/*
 WIDefaultListTableViewCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIDefaultListTableViewCell.h"
#import "WIListRowView.h"

@implementation WIDefaultListTableViewCell

@synthesize nameLabel       = _nameLabel;
@synthesize editing         = _editing;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if(self)
    {
        CGRect myFrame = self.frame;
        myFrame.size.height = 44.0;
        self.frame = myFrame;
           
        CGFloat nameLabelHeight = 30.0f;
        CGFloat margin = 15.0f;
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, self.topMargin, self.frame.size.width - (2*margin), nameLabelHeight)];
        nameLabel.textAlignment = UITextAlignmentLeft;
        nameLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:17.0f];
        nameLabel.backgroundColor = [UIColor whiteColor];
        nameLabel.numberOfLines = 0;
        self.nameLabel = nameLabel;
        
        [self addSubview:self.nameLabel];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    return self;
}

- (CGFloat)bottomMargin
{
    return 5;
}

- (CGFloat)topMargin
{
    return 10;
}

- (void)setEditing:(BOOL)editing
{
    if(_editing == editing)
    {
        return;
    }
    
    _editing = editing;
    
    CGRect nameLabelFrame = self.nameLabel.frame;
    
    if(!_editing)
    {
        nameLabelFrame.origin.x = 20;
        nameLabelFrame.size.width = self.frame.size.width - 5; 
    }
    else 
    {
        nameLabelFrame.origin.x = 40;
        nameLabelFrame.size.width = self.frame.size.width - 25;
    }
    
    self.nameLabel.frame = nameLabelFrame;
}

@end
