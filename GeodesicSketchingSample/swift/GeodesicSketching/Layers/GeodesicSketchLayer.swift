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

import UIKit
import ArcGIS

class GeodesicSketchLayer: AGSSketchGraphicsLayer {
   
    var geometryEngine = AGSGeometryEngine()
    
    // Override the method to get the desired functionality
    override func insertVertex(point: AGSPoint!, inPart partIndex: Int, atIndex coordinateIndex: Int) {
        
        // If we can no longer undo, then the next vertex inserted
        // will create a single point not a polyline so don't densify
        let firstPointPlaced = self.undoManager.canUndo
        
        // Call AGSSketchGraphicsLayer's insertVertex:inPart:atIndex: to get the existing functionality
        super.insertVertex(point, inPart:partIndex, atIndex:coordinateIndex)
        
        // Densify the geometry to get geodesic lines drawn rather than just straight lines
        if self.geometry is AGSPolyline && firstPointPlaced {
            let densified = self.geometryEngine.geodesicDensifyGeometry(self.geometry, withMaxSegmentLength:50, inUnit:AGSSRUnit.UnitSurveyMile) as! AGSPolyline
            
            self.applyGeometry(densified)
        }
    
    }
}
