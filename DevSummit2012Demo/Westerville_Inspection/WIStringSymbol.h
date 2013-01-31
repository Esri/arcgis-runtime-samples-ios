/*
 WIStringSymbol.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <ArcGIS/ArcGIS.h>

/*
 Subclass of AGSSimpleLineSymbol. Attempts to make symbol look like a raised
 piece of string
 */

@interface WIStringSymbol : AGSSimpleLineSymbol

//convenience class method
+ (WIStringSymbol *)stringSymbol;

@end
