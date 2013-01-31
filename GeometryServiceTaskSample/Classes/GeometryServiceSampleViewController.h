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

#define kBaseMapService			@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kGeometryBufferService	@"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Geometry/GeometryServer/buffer"

#define kesriSRUnit_SurveyMile	9035
#define kesriSRUnit_Meter		9001

#define kWebMercator			102100

@interface GeometryServiceSampleViewController : UIViewController <	AGSGeometryServiceTaskDelegate, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate > {
	
	UINavigationBar		*_navBar;
	UIButton			*_goBtn;
	UIButton			*_clearGraphicsBtn;		
	UIView				*_statusView;
	UILabel				*_statusLabel;		/* label that informs user to click points/number of pts clicked	*/
	
	AGSMapView			*_mapView;
	AGSGraphicsLayer	*_graphicsLayer;	
	
	NSMutableArray		*_geometryArray;	/* holds on to the buffered geometries until "clear" clicked		*/
	NSInteger			 _numPoints;		/* keeps track of the number of points the user has clicked			*/
	NSMutableArray		*_pushpins;			/* holds on to the pushpins that mark where the user clicks			*/
	
	AGSGeometryServiceTask *_gst;			/* The Geometry Service Task we will use to execute operations		*/
}

@property (nonatomic, strong) IBOutlet UIButton *goBtn;
@property (nonatomic, strong) IBOutlet UIButton *clearGraphicsBtn;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) NSMutableArray *geometryArray;
@property (nonatomic, strong) NSMutableArray *pushpins;

@property (nonatomic, strong) AGSGeometryServiceTask *gst;

/*  Called when the user clicks the "Go" button on the UINavigation Bar
 *  Kicks off the Geometry Service Task given the user has selected >= 1 point
 */
- (IBAction)goBtnClicked:(id)sender;


/*  Clears all of the graphics from the view
 */
- (IBAction)clearGraphicsBtnClicked:(id)sender;

@end

