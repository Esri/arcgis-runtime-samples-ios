/*
 WIIndexCardTableViewCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIIndexCardTableViewCell.h"
#import "WIIndexCardRowView.h"

@interface WIIndexCardTableViewCell () 

@property (nonatomic, strong) WIIndexCardRowView  *rowView;
@property (nonatomic, strong) UIImageView          *selectedRowImageView;

@end

@implementation WIIndexCardTableViewCell

@synthesize rowView                 = _rowView;
@synthesize nameLabel               = _nameLabel;
@synthesize selectedRow             = _selectedRow;
@synthesize selectedRowImageView    = _selectedRowImageView;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier isTitle:(BOOL)title
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self)
    {
        CGRect myFrame = self.frame;
        myFrame.size.height = 44.0;
        self.frame = myFrame;
        
        WIIndexCardRowView *rv = [[WIIndexCardRowView alloc] initWithFrame:self.frame isTitleRow:title];
        rv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.rowView = rv;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        
        CGFloat margin = 5.0f;
        CGFloat contentHeight = 30.0f;
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, self.frame.size.height - (margin + contentHeight), self.frame.size.width - margin, contentHeight)];
        nameLabel.textAlignment = UITextAlignmentLeft;
        nameLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:19.0];
        nameLabel.backgroundColor = [UIColor whiteColor];
        nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.nameLabel = nameLabel;
        
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
        iv.frame = CGRectMake(self.frame.size.width - (margin + contentHeight), self.frame.size.height - (margin + contentHeight), contentHeight, contentHeight);
        iv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        iv.hidden = YES;
        self.selectedRowImageView = iv;
                
        
        [self addSubview:self.rowView];
        [self addSubview:self.nameLabel];
        [self addSubview:self.selectedRowImageView];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)setSelectedRow:(BOOL)selectedRow
{
    _selectedRow = selectedRow;
    self.selectedRowImageView.hidden = !_selectedRow;
}

@end
