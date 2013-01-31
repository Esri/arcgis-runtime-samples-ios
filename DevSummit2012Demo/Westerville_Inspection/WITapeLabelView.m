/*
 WITapeLabelView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WITapeLabelView.h"

@implementation WITapeLabelView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithOrigin:(CGPoint)origin withName:(NSString *)name
{
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, 168, 70)];
    if(self)
    {
        self.image = [UIImage imageNamed:@"masking_tape_label.png"];
        
        CGRect labelRect = CGRectInset(self.bounds, 20, 3);
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:labelRect];
        nameLabel.textAlignment = UITextAlignmentCenter;
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.numberOfLines = 2;
        nameLabel.font = [UIFont fontWithName:@"MarkerFelt-Wide" size:20.0f];
        nameLabel.text = name;
        
        [self addSubview:nameLabel];
    }
    
    return self;
}

@end
