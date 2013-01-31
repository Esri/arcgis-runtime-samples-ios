/*
 WIInspectionFormCell.h
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

/* 
   Custom editable cell that is part of the inspection form. 
 */
@interface WIInspectionFormCell : UITableViewCell

@property (nonatomic, strong) UILabel       *fieldName;
@property (nonatomic, strong) UITextField   *fieldResult;

@end
