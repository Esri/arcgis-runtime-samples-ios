//
// Copyright 2014 ESRI
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

import UIKit
import ArcGIS

class CountyInfoTemplate: NSObject, AGSLayerCalloutDelegate {
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        let graphic = feature as! AGSGraphic
        callout.title =  graphic.attributeAsStringForKey("NAME")
        callout.detail = String(format: "'90: %@, '99: %@", graphic.attributeAsStringForKey("POP1990"), graphic.attributeAsStringForKey("POP1999"))
        return true
    }
}
