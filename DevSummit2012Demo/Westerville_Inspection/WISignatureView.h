/*
 WISignatureView.h
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
#import <QuartzCore/QuartzCore.h>

/* 
 This view provides a mechanism for adding a signature as an attachment. 
 */
@interface WISignatureView : UIView

/* The width of the signature in points */
@property (nonatomic, assign) CGFloat    lineWidth;

/* The color of the signature */
@property (nonatomic, strong) UIColor   *lineColor;

/* Indicates whether or not the user has started a signature */
@property (nonatomic, assign) BOOL      hasDrawing;

/* Clear the signature view */
- (void)reset;

/* Returns the UIImage representation of the signature */
- (UIImage*)exportSignatureImage;
@end
