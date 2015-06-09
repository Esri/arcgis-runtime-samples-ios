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

class ProjectViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var geometrySelect:UISegmentedControl!
    @IBOutlet weak var projectButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    @IBOutlet weak var mapView1:AGSMapView!
    @IBOutlet weak var mapView2:AGSMapView!
    @IBOutlet weak var mapView3:AGSMapView!
    
    var sketchLayer:AGSSketchGraphicsLayer!
    var graphicsLayer1:AGSGraphicsLayer!
    var graphicsLayer2:AGSGraphicsLayer!
    var graphicsLayer3:AGSGraphicsLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Map 1
        
        self.mapView1.layerDelegate = self
        
        //Adding empty graphics layer to set the map spatial reference to World_WGS84
        let gl = AGSGraphicsLayer(spatialReference: AGSSpatialReference.wgs84SpatialReference())
        self.mapView1.addMapLayer(gl)
        
        //Add world map service
        let map1Url = NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer")
        let dynamicLyr1 = AGSDynamicMapServiceLayer(URL: map1Url)
        self.mapView1.addMapLayer(dynamicLyr1, withName:"Dynamic Layer 1")
        
        // Add a graphics layer
        self.graphicsLayer1 = AGSGraphicsLayer()
        self.mapView1.addMapLayer(self.graphicsLayer1, withName:"GraphicsLayer 1")
        
        
        // Map 2
        
        self.mapView2.layerDelegate = self
        self.mapView2.userInteractionEnabled = false
        
        //Adding empty graphics layer to set the map spatial reference to World_Bonne
        let gl2 = AGSGraphicsLayer(spatialReference: AGSSpatialReference(WKID: 54024))
        self.mapView2.addMapLayer(gl2)
        
        
        //Add world map service
        let map2Url = NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let dynamicLyr2 = AGSDynamicMapServiceLayer(URL: map2Url)
        self.mapView2.addMapLayer(dynamicLyr2, withName:"Dynamic Layer 2")
        
        // Add a graphics layer
        self.graphicsLayer2 = AGSGraphicsLayer()
        self.mapView2.addMapLayer(self.graphicsLayer2, withName:"Graphics Layer 2")
        
        // Map 3
        
        
        self.mapView3.layerDelegate = self
        self.mapView3.userInteractionEnabled = false
        
        //Adding empty graphics layer to set the map spatial reference to World_Two_Point_Equidistant
        let gl3 = AGSGraphicsLayer(spatialReference: AGSSpatialReference(WKID: 54031))
        self.mapView3.addMapLayer(gl3)
        
        //Add world map service
        let map3Url = NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let dynamicLyr3 = AGSDynamicMapServiceLayer(URL: map3Url)
        self.mapView3.addMapLayer(dynamicLyr3, withName:"Dynamic Layer 3")
        
        // Add a graphics layer
        self.graphicsLayer3 = AGSGraphicsLayer()
        self.mapView3.addMapLayer(self.graphicsLayer3, withName:"Graphics Layer 3")
        
        // A composite symbol to represent the geometries
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline = nil
        
        
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(innerSymbol)
        
        // A renderer for the graphics layers
        let renderer = AGSSimpleRenderer(symbol: compositeSymbol)
        
        self.graphicsLayer1.renderer = renderer
        self.graphicsLayer2.renderer = renderer
        self.graphicsLayer3.renderer = renderer
        
        self.userInstructions.text = "Sketch a geometry on the upper map and tap the project button"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        // Add a sketch layer to the top map view
        if mapView == self.mapView1 {
            let polyline = AGSMutablePolyline(spatialReference: self.mapView1.spatialReference)
            self.sketchLayer = AGSSketchGraphicsLayer(geometry: polyline)
            self.mapView1.addMapLayer(self.sketchLayer, withName:"Sketch Layer")
            self.mapView1.touchDelegate = self.sketchLayer
            
        }
    }
    
    //MARK: - Toolbar actions
    
    @IBAction func project() {
    
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        // Create the graphic and add it to the top graphics layer
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol:nil, attributes:nil)
        
        self.graphicsLayer1.addGraphic(graphic)
        
        let geometryEngine = AGSGeometryEngine()
        
        // Project the geometry to the spatial references of the other mapViews and create new graphics from the projected geometries
        let map2Geometry = geometryEngine.projectGeometry(graphic.geometry, toSpatialReference:self.mapView2.spatialReference)
        let map2Graphic = AGSGraphic(geometry: map2Geometry, symbol:nil, attributes:nil)
        
        let map3Geometry = geometryEngine.projectGeometry(graphic.geometry, toSpatialReference:self.mapView3.spatialReference)
        let map3Graphic = AGSGraphic(geometry: map3Geometry, symbol:nil, attributes:nil)
        
        
        // Add the new graphics to the graphics layers
        self.graphicsLayer2.addGraphic(map2Graphic)
        
        self.graphicsLayer3.addGraphic(map3Graphic)
        
        self.sketchLayer.clear()
        
        self.userInstructions.text = "Sketch another geometry or tap the reset button to start over"
    }
    
    
    @IBAction func selectGeometry(geomControl:UISegmentedControl) {
    
        // Set the geometry of the sketch layer to match the selected geometry
        switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView1.spatialReference)
        case 1:
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView1.spatialReference)
        default:
            break
        }
        
        self.sketchLayer.clear()
    }
    
    
    @IBAction func reset() {
        self.graphicsLayer1.removeAllGraphics()
        self.graphicsLayer2.removeAllGraphics()
        self.graphicsLayer3.removeAllGraphics()
        self.sketchLayer.clear()
        
        self.userInstructions.text = "Sketch a geometry on the upper map and tap the project button"
    
    }
}
