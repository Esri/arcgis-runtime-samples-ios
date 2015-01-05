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

@protocol NotesViewControllerDelegate <NSObject>
@required
- (void)didFinishWithNotes;
@end

@interface NotesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AGSPopupsContainerDelegate, AGSFeatureLayerEditingDelegate, AGSFeatureLayerQueryDelegate>

@property (nonatomic, weak) id <NotesViewControllerDelegate> delegate;


//custom init method to instantiate with the incident OID
- (id)initWithIncidentOID:(NSNumber*)incidentOID incidentLayer:(AGSFeatureLayer *)layer;

@end
