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
@protocol TOCViewControllerDelegate ;

@interface TOCViewController : UIViewController

//mapView to create the TOC for
@property (nonatomic, weak) AGSMapView *mapView;

@property (nonatomic, weak) id <TOCViewControllerDelegate> delegate;

@end

@protocol TOCViewControllerDelegate <NSObject>

- (void)dismissTOCViewController:(TOCViewController*)controller;

@end