//
// Copyright 2015 ESRI
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

import Foundation
import ArcGIS

var elementLevelHandle: Int = 0

extension AGSMapContentsLegendElement {
    //custom property to set the level of the legend element in the mapsContentTree hierarchy
    var level:Int {
        get {
            if let optionalValue: AnyObject = objc_getAssociatedObject(self, &elementLevelHandle) {
                return optionalValue as! Int
            }
            return 0
        }
        set {
            objc_setAssociatedObject(self, &elementLevelHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}