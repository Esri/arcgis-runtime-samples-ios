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

#import "OfflineTileOperation.h"



@implementation OfflineTileOperation

- (id)initWithTileKey:(AGSTileKey *)tk dataFramePath:(NSString *)path target:(id)t action:(SEL)a {
	
	if (self = [super init]) {
		self.target = t;
		self.action = a;
		self.allLayersPath = [path stringByAppendingPathComponent:@"_alllayers"]  ;
		self.tileKey = tk;
		
	}
	return self;
}

-(void)main {
    //If this operation was cancelled, do nothing
    if(self.isCancelled)
        return;
    
	//Fetch the tile for the requested Level, Row, Column
	@try {
		//Level ('L' followed by 2 decimal digits)
		NSString *decLevel = [NSString stringWithFormat:@"L%02ld",(long)self.tileKey.level];
		//Row ('R' followed by 8 hex digits)
		NSString *hexRow = [NSString stringWithFormat:@"R%08lx",(long)self.tileKey.row];
		//Column ('C' followed by 8 hex digits)  
		NSString *hexCol = [NSString stringWithFormat:@"C%08lx",(long)self.tileKey.column];
		
		NSString* dir = [self.allLayersPath stringByAppendingFormat:@"/%@/%@",decLevel,hexRow];
		
		//Check for PNG file
		NSString *tileImagePath = [[NSBundle mainBundle] pathForResource:hexCol ofType:@"png" inDirectory:dir];
		
		if (nil != tileImagePath) {
			self.imageData= [NSData dataWithContentsOfFile:tileImagePath];
		}else {
			//If no PNG file, check for JPEG file
			tileImagePath = [[NSBundle mainBundle] pathForResource:hexCol ofType:@"jpg" inDirectory:dir];
			if (nil != tileImagePath) {
				self.imageData= [NSData dataWithContentsOfFile:tileImagePath];
			}

		}
		
	}
	@catch (NSException *exception) {
		NSLog(@"main: Caught Exception %@: %@", [exception name], [exception reason]);
	}
	@finally {
		//Invoke the layer's action method
        if(!self.isCancelled)
            [self.target performSelector:self.action withObject:self];
	}
}


@end


