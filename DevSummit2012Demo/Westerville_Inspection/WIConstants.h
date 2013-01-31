/*
 WIConstants.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

/*
 Several defines you can use to change the web map, routing service, etc.
 */

#define kPortalURL @"http://www.arcgis.com"

//The id of your web map on portal
#define kWebMapId @"898b954e995b446f980d2928f1088955"

//The network routing service
#define kRoutingServiceURL @"http://tasks.arcgisonline.com/ArcGIS/rest/services/NetworkAnalysis/Esri_Route_NA/NAServer/Route"

//Locator service for performing geocoding
#define kLocatorServiceURL @"http://tasks.arcgis.com/ArcGIS/rest/services/WorldLocator/GeocodeServer"

//A substring in your inspection layer that can be used to uniquely identify the feature service used for inspecting other features
#define kInspectionLayerSubstring @"Inspection"
