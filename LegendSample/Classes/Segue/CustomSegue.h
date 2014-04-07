// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import <UIKit/UIKit.h>

@interface CustomSegue : UIStoryboardSegue

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIPopoverController *popOverController;

@end
