/*
 WIInspectionView.h
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
#import "WIDomainPickerView.h"

@class AGSPopup;
@class AGSFeatureLayer;
@class WIInspection;
@protocol WIInspectionViewDelegate; 

/* 
 View representing our yellow inspection sheet 
 */
@interface WIInspectionView : UIView <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, 
                                        WIDomainPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                        UIActionSheetDelegate, UIPopoverControllerDelegate>

@property (nonatomic, unsafe_unretained) id<WIInspectionViewDelegate>     delegate;

//Starting a new inspection
- (id)initWithFrame:(CGRect)frame withFeatureToInspect:(AGSPopup *)feature inspectionLayer:(AGSFeatureLayer *)inspectionLayer;

//Editing a previous inspection
- (id)initWithFrame:(CGRect)frame inspection:(WIInspection *)inspection;

@end

/* delegate methods to notify us when an inspection is done being editing, or has been cancelled */
@protocol WIInspectionViewDelegate <NSObject>

@optional
- (void)inspectionView:(WIInspectionView *)inspectionView didCancelCollectingInspection:(WIInspection *)inspection;
- (void)inspectionView:(WIInspectionView *)inspectionView didFinishWithInspection:(WIInspection *)inspection;

@end
