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

#import "OfflineCacheParserDelegate.h"
#import <ArcGIS/ArcGIS.h>

@implementation OfflineCacheParserDelegate

#pragma mark -
#pragma mark NSXMLParserDelegate methods


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
    //Save the error
	self.error = parseError;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	self.currentElement = elementName;
    if ([self.currentElement isEqualToString:@"LODInfos"]){
		self.lods = [NSMutableArray array] ;
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)value
{
    if ([self.currentElement isEqualToString:@"XMin"]){
		_xmin = [value doubleValue];
	} else if ([self.currentElement isEqualToString:@"YMin"]){
		_ymin = [value doubleValue];
	} else if ([self.currentElement isEqualToString:@"XMax"]){
		_xmax = [value doubleValue];
	} else if ([self.currentElement isEqualToString:@"YMax"]){
		_ymax = [value doubleValue];
	}else if ([self.currentElement isEqualToString:@"WKID"]) {
		_WKID = [value intValue];
    }else if ([self.currentElement isEqualToString:@"WKT"]) {
		if(self.WKT!=nil){
			[self.WKT appendString:value];
		}else {
			self.WKT = [[NSMutableString alloc] initWithString:value];
		}
    }else if ([self.currentElement isEqualToString:@"X"]){
        _tileOriginX = [value doubleValue];
    }else if ([self.currentElement isEqualToString:@"Y"]){
        _tileOriginY = [value doubleValue];
    }else if ([self.currentElement isEqualToString:@"TileCols"]){
		_tileHeight = [value floatValue];
    }else if ([self.currentElement isEqualToString:@"TileRows"]){
        _tileWidth = [value floatValue];
    }else if ([self.currentElement isEqualToString:@"DPI"]){
        _dpi = [value intValue];
    }else if ([self.currentElement isEqualToString:@"LevelID"]){
        _level = [value intValue];
    }else if ([self.currentElement isEqualToString:@"Scale"]){
        _scale = [value doubleValue];
    }else if ([self.currentElement isEqualToString:@"Resolution"]){
        _resolution = [value doubleValue];
    }else if ([self.currentElement isEqualToString:@"CacheTileFormat"]){
		self.tileFormat = value;
	}else if([self.currentElement isEqualToString:@"StorageFormat"]){
		if(![value isEqualToString:@"esriMapCacheStorageModeExploded"]){
			NSDictionary* dict = [NSDictionary dictionaryWithObject:@"Only exploded format caches are supported" forKey:NSLocalizedDescriptionKey];
			self.error = [[NSError alloc] initWithDomain:@"Parsing conf.xml" code:0 userInfo:dict];
			[parser abortParsing];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    if ([elementName isEqualToString:@"LODInfo"]){
        self.lod = [[AGSLOD alloc]initWithLevel:_level resolution:_resolution scale:_scale];
		[self.lods addObject:_lod];
	}else if ([elementName isEqualToString:@"CacheInfo"]){
		_tileSize = CGSizeMake(_tileWidth, _tileHeight);
		self.spatialReference = [[AGSSpatialReference alloc] initWithWKID:_WKID WKT:_WKT];
		self.tileOrigin = [[AGSPoint alloc] initWithX:_tileOriginX y:_tileOriginY spatialReference:_spatialReference];
		self.fullEnvelope = [AGSEnvelope envelopeWithXmin:_xmin 
												 ymin:_ymin 
												 xmax:_xmax 
												 ymax:_ymax 
									 spatialReference:_spatialReference];
		self.tileInfo = [[AGSTileInfo alloc] initWithDpi: _dpi 
												   format:_tileFormat 
													 lods:_lods 
												   origin:_tileOrigin 
										 spatialReference:_spatialReference 
												 tileSize:_tileSize];
	}	
}        

- (void)parserDidEndDocument:(NSXMLParser *)parser 
{
	//Compute the start/end tile for each row & column
	if(self.fullEnvelope!=nil)
		[self.tileInfo computeTileBounds:_fullEnvelope];
}




			   
@end
