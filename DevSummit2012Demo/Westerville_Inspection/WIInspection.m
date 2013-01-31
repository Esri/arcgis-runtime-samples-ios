/*
 WIInspection.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIInspection.h"
#import <ArcGIS/ArcGIS.h>
#import "WISignatureView.h"
#import "WIAttributeUtility.h"
#import "AGSGeometry+Additions.h"

@interface WIInspection () 

@property (nonatomic, strong, readwrite) AGSPopup   *feature;

@end

@implementation WIInspection

@synthesize popup               = _popup;
@synthesize feature             = _feature;

@synthesize signatureView       = _signatureView;

@synthesize images              = _images;

@synthesize dateSynced          = _dateSynced;
@synthesize dateModified        = _dateModified;

@synthesize attributeUtility    = _attributeUtility;
@synthesize editableFieldInfos  = _editableFieldInfos;


- (id)initWithFeatureToInspect:(AGSPopup *)feature inspectionLayer:(AGSFeatureLayer *)inspectionLayer;
{
    self = [super init];
    if(self)
    {
        self.feature = feature;
        
        self.dateSynced     = nil;
        self.dateModified   = [NSDate date];
        
        self.images = [NSMutableArray array];
        
        //create new inspection (a popup) 
        AGSGraphic *inspectionFeature = nil;
        if (inspectionLayer.templates.count > 0) {
            inspectionFeature = [inspectionLayer featureWithTemplate:[inspectionLayer.templates objectAtIndex:0]];
        }
        else
        {
            inspectionFeature = [inspectionLayer featureWithType:[inspectionLayer.types objectAtIndex:0]];
        }
        
        inspectionFeature.geometry = [feature.graphic.geometry getLocationPoint];
        
        //add graphic to layer so edit properties can be set appropriately
        [inspectionLayer addGraphic:inspectionFeature];
        
        AGSPopupInfo *popupInfo = [AGSPopupInfo popupInfoForGraphic:inspectionFeature];
        
        self.popup = [AGSPopup popupWithGraphic:inspectionFeature popupInfo:popupInfo]; 
        
        //don't want edit geometry capability
        self.popup.allowEditGeometry = NO;
        
        //helps us create strings for each of the fields
        self.attributeUtility = [[WIAttributeUtility alloc] initWithPopup:self.popup];
        
        //create editable field infos array
        self.editableFieldInfos = [NSMutableArray arrayWithCapacity:self.popup.popupInfo.fieldInfos.count];
        for (AGSPopupFieldInfo *fi in self.popup.popupInfo.fieldInfos)
        {
            if (fi.editable) {
                [self.editableFieldInfos addObject:fi];
            }
        }
        
        //Pre-populate inspection form with values from the feature being inspected. This example assumes that attributes
        //with the same names are of the same type and just assigns those blindly to the inspection. For a real
        //app, a more defensive approach would be nice here
        NSArray *inspectionFieldNames = [[self.popup.graphic allAttributes] allKeys];
        NSArray *featureFieldNames = [[self.feature.graphic allAttributes] allKeys];
        NSArray *offLimitsFieldNames = [NSArray arrayWithObjects:@"OBJECTID", @"GlobalID", nil];
        
        for (NSString *fieldName in featureFieldNames) {
            if ([inspectionFieldNames containsObject:fieldName] && ![offLimitsFieldNames containsObject:fieldName]) {
                id featureValue = [self.feature.graphic attributeForKey:fieldName];
                [self.popup.graphic setAttribute:featureValue forKey:fieldName];
            }
        }
        
        //pre-populate date fields with current date. Dates won't be editable in this example
        for (AGSPopupFieldInfo *fi in self.popup.popupInfo.fieldInfos)
        {
            AGSField *field = [self.attributeUtility.fieldDictionary objectForKey:fi.fieldName];
            if ([self.attributeUtility isADateField:field]) {
                NSNumber *dateNum = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000.0];
                [self.popup.graphic setAttribute:dateNum forKey:fi.fieldName];
            }
        }

    }
    
    return self;
}

- (void)addAttachments
{
    AGSAttachmentManager *am = [self.attributeUtility.featureLayer attachmentManagerForFeature:self.popup.graphic];
    
    //if inspection has signature, add as attachment
    if(self.signatureView.hasDrawing)
    {
        UIImage *signatureImage = [self.signatureView exportSignatureImage];
        [am addAttachmentAsJpgWithImage:signatureImage name:@"Signature"];
    }
    
    //if inspection has an attached image, add it
    for(UIImage *image in self.images)
    {
        [am addAttachmentAsJpgWithImage:image name:@"Polaroid"];
    }
}

- (WISignatureView *)signatureView
{
    if(_signatureView == nil)
    {
        WISignatureView *sigView = [[WISignatureView alloc] initWithFrame:CGRectZero];
        sigView.backgroundColor = [UIColor clearColor];
        self.signatureView = sigView;
    }
    return _signatureView;
}

@end
