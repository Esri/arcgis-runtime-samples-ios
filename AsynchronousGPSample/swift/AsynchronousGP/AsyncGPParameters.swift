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

import Foundation
import ArcGIS

class AsyncGPParameters {
    var featureSet:AGSFeatureSet?
    var windDirection:NSDecimalNumber
    var materialType:String
    var dayOrNightIncident:String
    var largeOrSmallSpill:String
    
    init() {
        windDirection = NSDecimalNumber(double: 90)
        materialType = "Anhydrous ammonia"
        dayOrNightIncident = "Day"
        largeOrSmallSpill = "Large"
    }
    
    func parametersArray() -> [AGSGPParameterValue] {
        //create parameters
        let paramLoc = AGSGPParameterValue(name: "Incident_Point", type: .FeatureRecordSetLayer, value: self.featureSet!)
        let paramDegree = AGSGPParameterValue(name: "Wind_Bearing__direction_blowing_to__0_-_360_", type: .Double, value: self.windDirection.doubleValue)
        let paramMaterial = AGSGPParameterValue(name: "Material_Type", type: .String, value: self.materialType)
        let paramTime = AGSGPParameterValue(name: "Day_or_Night_incident", type: .String, value: self.dayOrNightIncident)
        let paramType = AGSGPParameterValue(name: "Large_or_Small_spill", type: .String, value: self.largeOrSmallSpill)
        
        let params:[AGSGPParameterValue] = [paramLoc, paramDegree, paramTime, paramType, paramMaterial]
        
        return params
    }
}