/*
 WIIndexCardRowView.h
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
 Used by an index card table view cell. Combining several row views into 
 a tableview will give the appearance of an index card.
 */

@interface WIIndexCardRowView : UIView

@property (nonatomic, assign) BOOL isTitleRow;

- (id)initWithFrame:(CGRect)frame isTitleRow:(BOOL)titleRow;

@end
