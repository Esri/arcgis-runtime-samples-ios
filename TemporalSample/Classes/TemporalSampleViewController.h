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

@interface TemporalSampleViewController : UIViewController <AGSLayerCalloutDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl* segmentControl;
@property (nonatomic, strong) NSDate* today;
@property (nonatomic, strong) AGSCalloutTemplate* calloutTemplate;
@property (nonatomic, strong) AGSFeatureLayer* featureLyr;

- (IBAction) datePicked;

@end

@interface TemporalSampleViewController (private)

- (void) assignValuesToSegmentedControlEndingWith:(NSDate*)today ;

@end

