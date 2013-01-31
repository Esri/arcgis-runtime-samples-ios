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
#import "InspectionFormViewController.h"

@class ClipboardView;
@class Reachability;
@class InspectionFormViewController;

/*
 The Clipboard View controller is the main view controller for the example. The class is
 responsible for the showing and interaction with the mao, giving the user the ability download 
 data for offline use, show informative messages about how many features have been downloaded, 
 whether the user has connectivity, etc.
 */

@interface ClipboardViewController : UIViewController <AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSMapViewCalloutDelegate, AGSCalloutDelegate,
                                                   InspectionFormDelegate, AGSFeatureLayerEditingDelegate,AGSAttachmentManagerDelegate,
                                                    AGSInfoTemplateDelegate> 
{
    /*Map Related Objects */
    AGSMapView *_mapView;
    AGSFeatureLayer *_featuresLayer;
    AGSFeatureLayer *_inspectionLayer;
    NSString *_inspectionLayerUrl;
    NSString *_featureLayerUrl;
    
    /*Inspections Array */
    NSMutableArray *_inspectionsToSync;
    
    /*Popup Stuff */
    AGSPopup *_currentFeatureToInspectPopup;
    AGSPopup *_currentInspectionPopup;
    
    /*IB Elements */
    UIImageView *_clipboard;
    UIImageView *_clip;
    UIView *_downloadDataView;
    UIView *_startInspectionView;
    UIView *_syncDataView;
    UIImageView *_downloadImageView;
    UIImageView *_startInpsectionImageView;
    UIImageView *_connectivityImageView;
    UIImageView *_downloadCheckImageView;
    UIImageView *_syncCheckImageView;
    UIImageView *_syncDataImageView;
    UILabel *_syncDataLabel;
    
    /*Misc. UX Elements */
    UIActivityIndicatorView *_activityIndicator;
    UIButton *_syncButton;
    
    /*Inpsection Sheet */
    InspectionFormViewController *_inspectionVC;
    
    /*Connectivity*/
    Reachability *_wifiReachability;
    
    @private
    int _numLayersLoaded;
    BOOL _downloadedData;
    BOOL _timerFired;
    BOOL _hasWifiConnection;
    
    unsigned int _inspectionIndex;
    NSMutableDictionary *_syncStatuses;
    
    BOOL _curled;
    BOOL _isSyncing;
}

/*IB Elements */
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UIImageView *clipboard;
@property (nonatomic, strong) IBOutlet UIImageView *clip;
@property (nonatomic, strong) IBOutlet UIView *downloadDataView;
@property (nonatomic, strong) IBOutlet UIView *startInspectionView;
@property (nonatomic, strong) IBOutlet UIView *syncDataView;
@property (nonatomic, strong) IBOutlet UIImageView *downloadImageView;
@property (nonatomic, strong) IBOutlet UIImageView *startInspectionImageView;
@property (nonatomic, strong) IBOutlet UIImageView *connectivityImageView;
@property (nonatomic, strong) IBOutlet UIImageView *downloadCheckImageView;
@property (nonatomic, strong) IBOutlet UIImageView *syncCheckImageView;
@property (nonatomic, strong) IBOutlet UIImageView *syncDataImageView;
@property (nonatomic, strong) IBOutlet UILabel *syncDataLabel;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *syncButton;

/*Main layers used in sample */
@property (nonatomic, strong) AGSFeatureLayer *featuresLayer;
@property (nonatomic, strong) AGSFeatureLayer *inspectionLayer;

/*Main layer urls */
@property (nonatomic, copy) NSString *inspectionLayerUrl;
@property (nonatomic, copy) NSString *featureLayerUrl;

/*For showing information about features to inspect */
@property (nonatomic, strong) AGSPopup *currentFeatureToInspectPopup;
@property (nonatomic, strong) AGSPopup *currentInspectionPopup;

@property (nonatomic, strong) NSMutableArray *inspectionsToSync;

/*For determining whether or not we have connectivity */
@property (nonatomic, strong) Reachability *wifiReachability;

/*Reference to an inspection form for the user to fill out */
@property (nonatomic, strong) InspectionFormViewController *inspectionVC;

/*What and how many features need to be synchronized when user gets
 connectivity back */
@property (nonatomic, strong) NSMutableDictionary *syncStatuses;

/*Button Actions */
-(IBAction)downloadData:(id)sender;
-(IBAction)startInspections:(id)sender;
-(IBAction)syncFeatures:(id)sender;
-(IBAction)curlMapButtonPressed:(id)sender;

@end
