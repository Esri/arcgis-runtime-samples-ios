/*
 WIBasemaps.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIBasemaps.h"

@implementation WIBasemaps

@synthesize onlineBasemaps  = _onlineBasemaps;
@synthesize localBasemaps   = _localBasemaps;


- (id)initWithOnlineBasemaps:(NSArray *)onlineBasemaps
{
    self = [super init];
    if(self)
    {
        self.onlineBasemaps = onlineBasemaps;
        
        //go grab local basemaps here
        //...
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *folder = [paths objectAtIndex:0];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:folder error:nil];
        NSMutableArray *localBasemaps = [NSMutableArray array];
        NSArray *extArray = [NSArray arrayWithObjects:@"tpk", @"zip", @"bundle", nil];
        for (NSString *s in filePaths) {
            // if the extension is one of the extentions we support as a local layer, add it
            if ([extArray containsObject:[s pathExtension]]) {
                NSString *name = [s stringByDeletingPathExtension];
                AGSLocalTiledLayer *localLayer = [[AGSLocalTiledLayer alloc] initWithName:name];
                [localBasemaps addObject:localLayer];
            }
        }
        self.localBasemaps = localBasemaps;
    }
    
    return self;
}

@end
