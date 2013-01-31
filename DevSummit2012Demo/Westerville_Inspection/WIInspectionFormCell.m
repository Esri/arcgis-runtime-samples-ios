/*
 WIInspectionFormCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIInspectionFormCell.h"

@implementation WIInspectionFormCell

@synthesize fieldName   = _fieldName;
@synthesize fieldResult = _fieldResult;



//Assuming a width of 600 right now...
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        UILabel *fieldLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, 193, 24)];
        fieldLabel.font = [UIFont fontWithName:@"Courier" size:20.0];
        fieldLabel.backgroundColor = [UIColor clearColor];
        fieldLabel.textColor = [UIColor blackColor];
        fieldLabel.textAlignment = UITextAlignmentRight;
        
        self.fieldName = fieldLabel;
        
        [self addSubview:self.fieldName];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(205, 35, 395, 1)];
        lineView.backgroundColor = [UIColor blackColor];
        
        [self addSubview:lineView];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(205, 8, 395, 31)];
        textField.font = self.fieldName.font;
        textField.borderStyle = UITextBorderStyleNone;
        textField.backgroundColor = [UIColor clearColor];
        textField.textColor = [UIColor blackColor];
        self.fieldResult = textField;
        
        [self addSubview:self.fieldResult];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
