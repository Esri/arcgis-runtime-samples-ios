/*
 WIDefaultListTableViewCell.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <UIKit/UIKit.h>
#import "WIListTableViewCell.h"

/*
 Subclasses AGSListTableViewCell and creates a default cell that includes
 a name label and an optional icon
 */

@interface WIDefaultListTableViewCell : WIListTableViewCell

@property (nonatomic, strong) UILabel   *nameLabel;
@property (nonatomic, assign) BOOL      editing;

- (CGFloat)bottomMargin;
- (CGFloat)topMargin;

@end
