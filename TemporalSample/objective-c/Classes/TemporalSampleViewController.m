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

#import "TemporalSampleViewController.h"

#define kTiledMapServiceURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kFeatureServiceURL @"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Earthquakes/EarthquakesFromLastSevenDays/FeatureServer/0"

@implementation TemporalSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Add an ArcGIS Online layer as basemap
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:
										 [NSURL URLWithString:kTiledMapServiceURL]];
	[self.mapView addMapLayer:tiledLyr withName:@"Base map Layer"];
	
	//Add Earthquakes layer showing earthquakes from last 7 days
	//Using Snapshot mode because number of earthquakes won't be too large (hopefully)
	self.featureLyr = [AGSFeatureLayer featureServiceLayerWithURL:
						   [NSURL URLWithString:kFeatureServiceURL] mode:AGSFeatureLayerModeSnapshot];
	self.featureLyr.outFields = [NSArray arrayWithObject:@"*"];
	self.featureLyr.calloutDelegate = self;
	[self.mapView addMapLayer:self.featureLyr withName:@"Earthquakes Layer"];


	//Customizing the callout look
	self.mapView.callout.accessoryButtonHidden = YES;
	self.mapView.callout.color = [UIColor colorWithRed:.475 green:.545 blue:.639 alpha:1];
	self.mapView.callout.titleColor = [UIColor whiteColor];
	self.mapView.callout.detailColor = [UIColor whiteColor];
	
	//Dynamically assigning values to the segmented control
	//Using the past 5 days
	self.today = [NSDate date];
	[self assignValuesToSegmentedControlEndingWith:self.today];
    
    [self.mapView enableWrapAround];
	
}

- (IBAction) datePicked {
	//if final segment 
	if(self.segmentControl.selectedSegmentIndex == self.segmentControl.numberOfSegments-1){
		//Show all earthquakes
		self.mapView.timeExtent = nil;
	}else {
		//Show earthquakes from selected date
		NSCalendar *calendar = [NSCalendar currentCalendar];
		
		NSDateComponents *offset = [[NSDateComponents alloc] init];
		
		//Based on selected segment, find the start of the desired date 
		[offset setDay:-self.segmentControl.selectedSegmentIndex];
		NSDate* picked =  [calendar dateByAddingComponents:offset toDate:self.today options:0];
		offset =  [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:picked];
		NSTimeInterval seconds = [offset second] + (60*[offset minute]) + (3600*[offset hour]);
		NSDate* start = [NSDate dateWithTimeIntervalSinceReferenceDate: ([picked timeIntervalSinceReferenceDate]-seconds)];
		
		//Also, find the end of the desired date
		offset = [[NSDateComponents alloc] init];
		[offset setDay:1];
		NSDate* end =  [calendar dateByAddingComponents:offset toDate:start options:0];
		
		//Set a time extent ranging from start to end
		AGSTimeExtent* extent = [[AGSTimeExtent alloc] initWithStart:start end:end];
		self.mapView.timeExtent = extent;

		//hide callout incase it was pointing to an earthquake from another date
		self.mapView.callout.hidden = YES;

	}
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}



#pragma mark -
#pragma mark AGSLayerCalloutDeleage methods
-(BOOL)callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint{
    AGSGraphic* graphic = (AGSGraphic*)feature;
    //title text for callout
    BOOL exists;
	NSString* title = [NSString stringWithFormat:@"Magnitude: %.1f",
					   [graphic attributeAsDoubleForKey:@"magnitude" exists:&exists]];
	callout.title  = title;
    
	NSString* detail = [NSString stringWithFormat:@"Depth: %.1f km, %@",
						[graphic attributeAsDoubleForKey:@"depth" exists:&exists],
						[graphic attributeAsStringForKey:@"region"]];
    callout.detail = detail;
    return YES;
}

@end

#pragma mark -
#pragma mark private methods

@implementation TemporalSampleViewController (private)

- (void) assignValuesToSegmentedControlEndingWith:(NSDate*)today {
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd MMM"]; //Ex: 05 Jan

	NSDateComponents *offset = [[NSDateComponents alloc] init];
	
	//segmentControl.numberOfSegments = 6 in the xib file
	//Assigning values of 5 recent days to the first 5 segments
	for(int i=0;i<self.segmentControl.numberOfSegments-1;i++){
		[offset setDay:-i];
		NSDate* temp =  [calendar dateByAddingComponents:offset toDate:today options:0];
		NSString* str = [formatter stringFromDate:temp];
		[self.segmentControl setTitle:str forSegmentAtIndex:i];
	}
	//Assigning value ALL to last segment
	[self.segmentControl setTitle:@"All" forSegmentAtIndex:self.segmentControl.numberOfSegments-1];
	[self.segmentControl setSelectedSegmentIndex:self.segmentControl.numberOfSegments-1];
}

@end

