// Copyright 2012 ESRI
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
#import <ArcGIS/ArcGIS.h>
#import "FeatureTemplatePickerViewController.h"
#import "LoadingView.h"

@interface FeatureLayerEditingSampleViewController : UIViewController<AGSCalloutDelegate, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate, FeatureTemplatePickerDelegate, UIAlertViewDelegate> {
    
	AGSMapView *_mapView;
    AGSMap* _webmap;
	AGSFeatureLayer *_featureLayer;
    AGSPopupsViewController* _popupVC;
    AGSFeature* _newFeature;
    AGSSketchEditor* _sketchEditor;

    UIView* _bannerView;
    UIAlertView* _alertView;
    UIBarButtonItem* _pickTemplateButton;
    UIBarButtonItem* _sketchCompleteButton;

    //
    LoadingView* _loadingView;
    FeatureTemplatePickerViewController* _featureTemplatePickerViewController;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSMap* webmap;
@property (nonatomic, strong) AGSFeatureLayer *activeFeatureLayer;
@property (nonatomic, strong) AGSPopup *popup;
@property (nonatomic, strong) AGSPopupsViewController* popupVC;
@property (nonatomic, strong) AGSSketchEditor* sketchEditor;

@property (nonatomic, strong) FeatureTemplatePickerViewController* featureTemplatePickerViewController;

@property (nonatomic, strong) IBOutlet UIView* bannerView;
@property (nonatomic, strong) UIAlertView* alertView;
@property (nonatomic, strong) UIBarButtonItem* pickTemplateButton;
@property (nonatomic, strong) UIBarButtonItem* sketchCompleteButton;
@property (nonatomic, strong) LoadingView* loadingView;

@end

