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

var expandedHandle: Bool = false
var levelHandle: Int = 0

extension AGSMapContentsLayerInfo {
    //custom property to check if the layer info is expanded or collapsed
    var expanded:Bool {
        get {
            if let optionalValue: AnyObject = objc_getAssociatedObject(self, &expandedHandle) {
                return optionalValue as! Bool
            }
            return false
        }
        set {
            objc_setAssociatedObject(self, &expandedHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    //custom property to set the level of the layer info in the mapsContentTree hierarchy
    var level:Int {
        get {
            if let optionalValue: AnyObject = objc_getAssociatedObject(self, &levelHandle) {
                return optionalValue as! Int
            }
            return 0
        }
        set {
            objc_setAssociatedObject(self, &levelHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
