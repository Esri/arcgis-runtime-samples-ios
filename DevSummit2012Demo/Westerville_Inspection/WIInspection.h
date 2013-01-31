/*
 WIInspection.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <Foundation/Foundation.h>

/*
 Container for the popup representing the inspection feature as well as
 the view representing the signature for the inspection.
 */

@class AGSPopup;
@class WISignatureView;
@class WIAttributeUtility;
@class AGSFeatureLayer;

/* Object to hold all information pertaining to our inspection */
@interface WIInspection : NSObject

@property (nonatomic, strong) AGSPopup              *popup;
@property (nonatomic, strong, readonly) AGSPopup    *feature;

@property (nonatomic, strong) WISignatureView      *signatureView;

@property (nonatomic, strong) NSMutableArray        *images;

@property (nonatomic, strong) NSDate                *dateModified;
@property (nonatomic, strong) NSDate                *dateSynced;

@property (nonatomic, strong) WIAttributeUtility   *attributeUtility;
@property (nonatomic, strong) NSMutableArray        *editableFieldInfos;

- (id)initWithFeatureToInspect:(AGSPopup *)feature inspectionLayer:(AGSFeatureLayer *)inspectionLayer;
- (void)addAttachments;

@end
