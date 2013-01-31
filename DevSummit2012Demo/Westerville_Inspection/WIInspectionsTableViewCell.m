/*
 WIInspectionsTableViewCell.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIInspectionsTableViewCell.h"

@interface WIInspectionsTableViewCell () 

@property (nonatomic, strong) UILabel           *dateLabel;
@property (nonatomic, strong) NSDateFormatter   *dateFormatter;

@end

@implementation WIInspectionsTableViewCell

@synthesize syncedInspection    = _syncedInspection;
@synthesize date                = _date;
@synthesize dateLabel           = _dateLabel;
@synthesize dateFormatter       = _dateFormatter;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if(self)
    {
        //give name a hardcoded name
        self.nameLabel.text = @"Inspection";
        
        //Modify position of name label to make room for date label
        CGRect nameLabelRect = self.nameLabel.frame;
        CGFloat fullNameWidth = nameLabelRect.size.width;
        nameLabelRect.size.width = fullNameWidth/4;   //only needs a quarter of the space
        self.nameLabel.frame = nameLabelRect;
        
        CGRect dateLabelRect = nameLabelRect;
        dateLabelRect.origin.x += nameLabelRect.size.width;
        dateLabelRect.size.width = (fullNameWidth*3)/4;  //take up 75% of the available space
        
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:dateLabelRect];
        dateLabel.textAlignment = UITextAlignmentRight;
        dateLabel.font = self.nameLabel.font;
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.numberOfLines = 0;
        self.dateLabel = dateLabel;
        
        [self addSubview:self.dateLabel];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"M/d/yy H:m"];
        self.dateFormatter = df;
    }
    
    return self;
}

- (void)setSyncedInspection:(BOOL)syncedInspection
{    
    _syncedInspection = syncedInspection;
    
    if(_syncedInspection)
    {
        self.dateLabel.textColor = [UIColor colorWithRed:0 green:(100.0/255.0) blue:0 alpha:1.0];
    }
    else 
    {
        self.dateLabel.textColor = [UIColor redColor];
    }
}

- (void)setDate:(NSDate *)date
{
    _date = date;
    
    self.dateLabel.text = [NSString stringWithFormat:@"%@: %@", (self.syncedInspection) ? @"Synced" : @"Modified", [self.dateFormatter stringFromDate:self.date]];
}

@end
