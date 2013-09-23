// Copyright 2010 ESRI
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

#import "MessageMil2525cSampleViewController.h"

@implementation MessageMil2525cSampleViewController

@synthesize mapView = _mapView;
@synthesize groupLayer = _groupLayer;
@synthesize mProcessor = _mProcessor;
@synthesize message = _message;
@synthesize milMessages = _milMessages;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    //Set the delegate for the map view
	self.mapView.layerDelegate = self;
    
	//Create an instance of a tiled map service layer
	AGSTiledMapServiceLayer *tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:[NSURL URLWithString:kTiledMapServiceURL]];
	
	//Add it to the map view
	[self.mapView addMapLayer:tiledLayer withName:@"Tiled Layer"];

	//Release to avoid memory leaks
	[tiledLayer release];
    
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:4326];
    
    //Create envelope defining location of message file
    AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-2.13 ymin:51.24 xmax:-1.93 ymax:51.44 spatialReference:sr];
    
	[self.mapView zoomToEnvelope:env animated:YES];
	
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
	self.mapView = nil;
    [super dealloc];
}


#pragma mark AGSMapViewLayerDelegate methods


-(void) mapViewDidLoad:(AGSMapView*)mapView {
    
    //Create a Group Layer
    self.groupLayer = [[AGSGroupLayer alloc] init];
    
    //Add the Group Layer to the MapView
    [self.mapView addMapLayer:self.groupLayer withName:@"Message Processing Group Layer"];

    //Create a message processor
    //Pass the symbol dictionary type and the group layer in the Constructor

    self.mProcessor = [[AGSMPMessageProcessor alloc]
                      initWithSymbolDictionaryType:AGSMPSymbolDictionaryTypeMil2525C
                      groupLayer:self.groupLayer];
    
    //Create the file path to the military message json file
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"Mil2525CMessages"
                                                        ofType:@"json"
                                                   inDirectory:nil];
    
    //Create a JSON Parser
    AGSSBJsonParser *parser = [[AGSSBJsonParser alloc] init];
    
    //Store the contents of the JSON file in a string
    NSString *jsonString = [NSString stringWithContentsOfFile:filePath
                                                    encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    //Store the JSON string in a dictionary
    NSDictionary *json = [parser objectWithString:jsonString];
    
    
    
    //Decode the JSON in the dictionary
    self.milMessages = [AGSJSONUtility decodeFromDictionary:json
                                                    withKey:@"messages"
                                                  fromClass:[Mil2525Message class]];
    
    //Process every message in the decoded JSON
    for (Mil2525Message *message in self.milMessages) {
        [self.mProcessor processMessage:message.message];
    }

}

@end

@interface Mil2525Message () {
    AGSMPMessage *_message;
}

@end

@implementation Mil2525Message

//this class is used for reading in the sample json messages...

#pragma mark -
#pragma mark AGSCoding

- (id)initWithJSON:(NSDictionary *)json {
    
	if (self = [self init]){
		[self decodeWithJSON:json];
	}
    
    return self;
}


-(void)decodeWithJSON:(NSDictionary *)json {
    
    self.message = [[AGSMPMessage alloc] init];
    
    for(id key in json){
        [self.message setProperty:[json objectForKey:key] forKey:key];
    }
    
}

@end

