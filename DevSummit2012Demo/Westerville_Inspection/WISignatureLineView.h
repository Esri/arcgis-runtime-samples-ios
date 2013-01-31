/*
 WISignatureLineView.h
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
    Object representing the "line" on which the inspector should sign 
 */
@interface WISignatureLineView : UIView

// rect to place the "X" denoting where to sign
-(CGRect)xRect;

@end
