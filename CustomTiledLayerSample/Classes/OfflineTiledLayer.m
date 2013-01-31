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

#import "OfflineTiledLayer.h"
#import "OfflineTileOperation.h"
#import "OfflineCacheParserDelegate.h"

//Function to convert [UNIT] component in WKT to AGSUnits
int MakeAGSUnits(NSString* wkt){
	NSString* value ;
	BOOL _continue = YES;
 	NSScanner* scanner = [NSScanner scannerWithString:wkt];
	//Scan for the UNIT information in WKT. 
	//If WKT is for a Projected Coord System, expect two instances of UNIT, and use the second one
	while (_continue) {
		[scanner scanUpToString:@"UNIT[\"" intoString:NULL];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"UNIT[\""]];
		_continue = [scanner scanUpToString:@"\"" intoString:&value];
	}
	if([@"Foot_US" isEqualToString:value] || [@"Foot" isEqualToString:value]){
		return AGSUnitsFeet;
	}else if([@"Meter" isEqualToString:value]){
		return AGSUnitsMeters;
	}else if([@"Degree" isEqualToString:value]){
		return AGSUnitsDecimalDegrees;
	}else{
		//TODO: Not handling other units like Yard, Chain, Grad, etc
		return -1;
	}
}


@implementation OfflineTiledLayer

@synthesize dataFramePath=_dataFramePath;

-(AGSUnits)units{
	return _units;
}
 
-(AGSSpatialReference *)spatialReference{
	return _fullEnvelope.spatialReference;
}
 
-(AGSEnvelope *)fullEnvelope{
	return _fullEnvelope;
}
 
-(AGSEnvelope *)initialEnvelope{
	//Assuming our initial extent is the same as the full extent
	return _fullEnvelope;
}

-(AGSTileInfo*) tileInfo{
	return _tileInfo;
}


#pragma mark -
- (id)initWithDataFramePath: (NSString *)path error:(NSError**) outError {
	
	if (self = [super init]) {
		self.dataFramePath = path;
		
		//Parse the conf.cdi file			
		NSString* confCDI = [[NSBundle mainBundle] pathForResource:@"conf" ofType:@"cdi" inDirectory: _dataFramePath ];
		NSXMLParser*  xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:confCDI]];
		OfflineCacheParserDelegate* parserDelegate = [[OfflineCacheParserDelegate alloc] init];
		[xmlParser setDelegate:parserDelegate];
		[xmlParser parse];
		
		//Parse the conf.xml file
		NSString* confXML = [[NSBundle mainBundle] pathForResource:@"conf" ofType:@"xml" inDirectory: _dataFramePath];
		xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:confXML]];
		[xmlParser setDelegate:parserDelegate];
		[xmlParser parse];
		
		//If XML files were parsed properly...
		if([parserDelegate tileInfo]!= nil && [parserDelegate fullEnvelope]!=nil ){
			//... get the metadata
			_tileInfo = [parserDelegate tileInfo];
			_fullEnvelope = [parserDelegate fullEnvelope];
			_units = MakeAGSUnits(_fullEnvelope.spatialReference.wkt);
            //Now that we have all the information required...
            //Inform the superclass that we're done
			[super layerDidLoad];
		}else {
			//... return error
            if (outError != NULL) {
                *outError = [parserDelegate error];
            }

			return nil;
		}
    }
    return self;
}

#pragma mark -
#pragma AGSTiledLayer (ForSubclassEyesOnly)
- (void)requestTileForKey:(AGSTileKey *)key{
    //Create an operation to fetch tile from local cache
	OfflineTileOperation *operation =
    [[OfflineTileOperation alloc] initWithTileKey:key
                                 dataFramePath:_dataFramePath
                                        target:self
                                        action:@selector(didFinishOperation:)];
    
   
	//Add the operation to the queue for execution
    [ [AGSRequestOperation sharedOperationQueue] addOperation:operation];
}

- (void)cancelRequestForKey:(AGSTileKey *)key{
    //Find the OfflineTileOperation object for this key and cancel it
    for(NSOperation* op in [AGSRequestOperation sharedOperationQueue].operations){
        if( [op isKindOfClass:[OfflineTileOperation class]]){
            OfflineTileOperation* offOp = (OfflineTileOperation*)op;
            if([offOp.tileKey isEqualToTileKey:key]){
                [offOp cancel];
            }
        }
    }
}



- (void) didFinishOperation:(OfflineTileOperation*)op {
    //... pass the tile's data to the super class
    [super setTileData: op.imageData  forKey:op.tileKey];
}

#pragma mark -

@end

