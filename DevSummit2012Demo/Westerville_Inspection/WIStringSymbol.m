/*
 WIStringSymbol.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIStringSymbol.h"

@implementation WIStringSymbol

+ (WIStringSymbol *)stringSymbol
{
    WIStringSymbol *sls = [[WIStringSymbol alloc] initWithColor:[UIColor colorWithRed:(186.0/255.0) green:0 blue:0 alpha:1.0]
                                                            width:4.0f];
    
    return sls;
}


//Custom override. Adds shadow to the symbol to make it look like there is some depth over the map
//- (void)applySymbolToContext:(CGContextRef)context withGraphic:(AGSGraphic*)graphic{
//	
//    [super applySymbolToContext:context withGraphic:graphic];
//    
//
//    CGColorRef shadowColor = [[[UIColor blackColor] colorWithAlphaComponent:0.8f] CGColor];   
//    
//    CGContextSaveGState(context);
//    CGContextSetShadowWithColor(context, CGSizeMake(3.0, 2.5), 1.5, shadowColor);
//}

@end
