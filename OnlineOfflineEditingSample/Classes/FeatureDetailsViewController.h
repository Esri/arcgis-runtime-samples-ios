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

@class FeatureTypeViewController;
@class OnlineOfflineFeatureLayer;

@interface FeatureDetailsViewController : UITableViewController<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,AGSFeatureLayerEditingDelegate> {
	
	OnlineOfflineFeatureLayer *_featureLayer;
	AGSGraphic *_feature;					
	AGSGeometry *_featureGeometry;					
	NSMutableArray *_attachments;			// any attachments, for not newFeature it will start filled with NSNull, then populated as we retrieve the data for the attachments (happens when they click on to view an attachment)
	NSDate *_date;							// date of when the feature was created
	NSDateFormatter *_dateFormat;			// used for displaying the date
	NSDateFormatter *_timeFormat;			// used for displaying the time
	int _objectId;							// object id of the feature passed in, or created feature
	BOOL _newFeature;						// flag that indicates whether the feature for which details are being viewed is new or existing
	NSArray *_attachmentInfos;				// when the feature is already existing, then we query for the attachment infos, store them in this var
	NSMutableArray *_operations;			// all the in-progress operations spawned by this VC, we keep them so we can cancel them if we pop the VC (dealloc cancels them)
	NSOperation *_retrieveAttachmentOp;		// keep track of the retrieve attachment op so that we only do one of these at a time
}

@property (nonatomic, retain) AGSGraphic *feature;
@property (nonatomic, retain) AGSGeometry *featureGeometry;
@property (nonatomic, retain) OnlineOfflineFeatureLayer *featureLayer;
@property (nonatomic, retain) NSMutableArray *attachments;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSDateFormatter *dateFormat;
@property (nonatomic, retain) NSDateFormatter *timeFormat;
@property (nonatomic, retain) NSArray *attachmentInfos;
@property (nonatomic, retain) NSMutableArray *operations;
@property (nonatomic, retain) NSOperation *retrieveAttachmentOp;

-(id)initWithFeatureLayer:(OnlineOfflineFeatureLayer*)featureLayer feature:(AGSGraphic *)feature featureGeometry:(AGSGeometry*)featureGeometry;
-(void)didSelectFeatureType:(FeatureTypeViewController *)ftvc;

@end
