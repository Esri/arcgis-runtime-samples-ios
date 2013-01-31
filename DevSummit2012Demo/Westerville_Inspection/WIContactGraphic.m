/*
 WIContactGraphic.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIContactGraphic.h"

@implementation WIContactGraphic

@synthesize contactName = _contactName;


- (id)initWithLocation:(AGSPoint *)location contactName:(NSString *)name;
{
    AGSPictureMarkerSymbol *pms = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"address_icon.png"]];
    pms.size = CGSizeMake(40.0f, 40.0f);
    
    self = [super initWithGeometry:location symbol:pms attributes:nil infoTemplateDelegate:nil];
    if(self)
    {
        self.contactName = name;
    }
    
    return self;
}

//Convenience class method
+ (WIContactGraphic *)contactGraphicWithLocation:(AGSPoint *)location contactName:(NSString *)name
{
    WIContactGraphic *cg = [[WIContactGraphic alloc] initWithLocation:location contactName:name];
    return cg;
}

@end
