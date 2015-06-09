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

class UnionDifferenceViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var segmentedControl:UISegmentedControl!
    @IBOutlet weak var userInstructions:UILabel!
    
    var sketchLayer:AGSSketchGraphicsLayer!
    var graphicsLayer:AGSGraphicsLayer!
    var unionGraphic:AGSGraphic!
    var differenceGraphic:AGSGraphic!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.showMagnifierOnTapAndHold = true
        self.mapView.enableWrapAround()
        self.mapView.layerDelegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        
        // Symbols to display geometries
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        let pointSymbol = AGSSimpleMarkerSymbol()
        pointSymbol.color = UIColor.redColor()
        pointSymbol.style = .Circle
        
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline = nil
        
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(pointSymbol)
        compositeSymbol.addSymbol(innerSymbol)
        
        
        // A renderer for the graphics layer
        let simpleRenderer = AGSSimpleRenderer(symbol: compositeSymbol)
        
        // Create and add a graphics layer to the map
        self.graphicsLayer = AGSGraphicsLayer()
        self.graphicsLayer.renderer = simpleRenderer
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        self.userInstructions.text = "Draw two intersecting polygons by tapping on the map"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        // Create a sketch layer and add it to the map
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        self.mapView.touchDelegate = self.sketchLayer
    }

    //MARK: - Toolbar actions
    
    @IBAction func add() {
        
        //Get the geometry of the sketch layer
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        //Create the graphic and add it to the graphics layer
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol:nil, attributes:nil)
        
        self.graphicsLayer.addGraphic(graphic)
        
        self.sketchLayer.clear()
        
        // If we have two graphics
        if self.graphicsLayer.graphics.count == 2 {
            self.addButton.enabled = false
            let geometryEngine = AGSGeometryEngine()
            
            // Get the geometries from the graphics layer
            let geometry1 = self.graphicsLayer.graphics[0].geometry
            let geometry2 = self.graphicsLayer.graphics[1].geometry
            
            // Make a new graphic with the difference of the two geometries
            let differenceGeometry = geometryEngine.differenceOfGeometry(geometry1, andGeometry:geometry2)
            self.differenceGraphic = AGSGraphic(geometry: differenceGeometry, symbol:nil, attributes:nil)
            
            let geometries = [geometry1,geometry2]
            
            // Make a new graphic with the union of the geometries
            self.unionGraphic = AGSGraphic(geometry: geometryEngine.unionGeometries(geometries), symbol:nil, attributes:nil)
            
            self.unionDifference(self.segmentedControl)
            self.userInstructions.text = "Toggle union and difference"
        }
    }
    
    @IBAction func reset() {
        self.graphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
        
        self.unionGraphic = nil
        self.differenceGraphic = nil
        
        self.addButton.enabled = true
        self.userInstructions.text = "Draw two intersecting polygons by tapping on the map"
    }
    
    @IBAction func unionDifference(segmentedControl:UISegmentedControl) {
        
        // Set the graphic for the selected operation
        if self.unionGraphic != nil && self.differenceGraphic != nil {
            if segmentedControl.selectedSegmentIndex == 0 {
                self.graphicsLayer.removeAllGraphics()
                self.graphicsLayer.addGraphic(self.unionGraphic)
            }
            else {
                self.graphicsLayer.removeAllGraphics()
                self.graphicsLayer.addGraphic(self.differenceGraphic)
            }
        }
    }
}
