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


#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@protocol OnlineOfflineDelegate <NSObject>

@optional

-(void)prepForOfflineUseCompleted:(BOOL)succeeded;
-(void)takeOnlineCompleted:(BOOL)succeeded;

@end

@interface OnlineOfflineFeatureLayer : AGSFeatureLayer <AGSFeatureLayerQueryDelegate, AGSFeatureLayerEditingDelegate, UIAlertViewDelegate> {
    BOOL _bOnline;
    NSOperation *_offlineFeaturesQueryOperation;
    NSMutableArray *_addedFeaturesArray;
    NSMutableArray *_addedAttachmentsArrays;
    NSOperation *_addOfflineFeaturesOperation;
    id onlineOfflineDelegate;
    NSMutableArray *_operations;
}

@property (nonatomic, assign) BOOL bOnline;
@property (nonatomic, retain) NSOperation *offlineFeaturesQueryOperation;
@property (nonatomic, retain) NSMutableArray *addedFeaturesArray;
@property (nonatomic, retain) NSMutableArray *addedAttachmentsArrays;
@property (nonatomic, retain) NSOperation *addOfflineFeaturesOperation;
@property (nonatomic, retain) NSMutableArray *operations;

@property (nonatomic, assign) id onlineOfflineDelegate;

+ (id)featureServiceLayerWithURL:(NSURL *)url mode:(AGSFeatureLayerMode)mode online:(BOOL)online;

-(void)prepForOfflineUse:(AGSEnvelope *)extent;

-(void)commitOfflineFeatures;
-(NSString *)addedFeaturesFilename;

-(void)addOfflineFeature:(AGSGraphic *)feature withAttachments:(NSArray *)attachments;

@end
