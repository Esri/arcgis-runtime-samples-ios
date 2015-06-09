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


class GeodesicSketchingViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var undoButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var redoButton:UIBarButtonItem!
    @IBOutlet weak var bannerLabel:UILabel!
    var currentDistance:Double!
    
    var sketchLayer:GeodesicSketchLayer!
    var graphicsLayer:AGSGraphicsLayer!
    var geometryEngine:AGSGeometryEngine!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Show magnifier to help with sketching
        self.mapView.showMagnifierOnTapAndHold = true
        
        // Enable wrap around for the map
        self.mapView.enableWrapAround()
        
        // Assign delegate to this view controller
        self.mapView.layerDelegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Graphics layer to hold all sketches (points and polylines)
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        //A symbol for the graphics layer's renderer to symbolize the sketches
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        // Create a renderer with the symbol and set the graphic layer's renderer property
        let renderer = AGSSimpleRenderer(symbol: lineSymbol)
        self.graphicsLayer.renderer = renderer
        
        // Instructions for the user
        self.bannerLabel.text = "Tap on the map to draw a flight path"
        
        // Start the distance out at zero
        self.currentDistance = 0
        
        // Add the sketch layer
        self.sketchLayer = GeodesicSketchLayer()
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        
        //Register for touch events
        self.mapView.touchDelegate = self.sketchLayer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func enableSketching() {
    
        // Don't show the intermediate vertices
        self.sketchLayer.midVertexSymbol = nil
        self.sketchLayer.vertexSymbol = nil
        
        let plane = AGSPictureMarkerSymbol(imageNamed: "tinyplane.png")
        self.sketchLayer.selectedVertexSymbol = plane
        
        // Set the sketch layer's geometry to a mutable polyline
        self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        
        // Reset the distance to 0
        self.currentDistance = 0
    
    }
    
    // Called when the map view has loaded
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        // Setup the sketch layer
        self.enableSketching()
        
        //Register for "Geometry Changed" notifications
        //We want to enable/disable UI elements when sketch geometry is modified
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"respondToGeomChanged:", name:AGSSketchGraphicsLayerGeometryDidChangeNotification, object:nil)
        
        // Get an initialized autoreleased geometry engine
        self.geometryEngine = AGSGeometryEngine()
    
    }
    
    func respondToGeomChanged(notification: NSNotification) {
        // Enable/Disable redo, undo, and add buttons
        self.undoButton.enabled = self.sketchLayer.undoManager.canUndo
        self.redoButton.enabled = self.sketchLayer.undoManager.canRedo
        self.addButton.enabled = self.undoButton.enabled
        
        // Get the distance of the flight path in miles
        self.currentDistance = self.geometryEngine.geodesicLengthOfGeometry(self.sketchLayer.geometry, inUnit:.UnitSurveyMile)
        
        
        // If the current distance is greater than zero we have a line so report it
        // otherwise instruct the user
        if self.currentDistance > 0 {
            self.bannerLabel.text = "Distance: \(Int(self.currentDistance)) miles"
        }
        else {
            self.bannerLabel.text = "Tap on the map to draw a flight path"
        }
    }
    
    // The undo action gets called when the undo button is pressed
    @IBAction func undo() {
        if self.sketchLayer.undoManager.canUndo { //extra check, just to be sure
            self.sketchLayer.undoManager.undo()
        }
    }
    
    // The redo action gets called when the redo button is pressed
    @IBAction func redo() {
        if self.sketchLayer.undoManager.canRedo {
            self.sketchLayer.undoManager.redo()
        }
    }
    
    // The reset action gets called when the reset button is pressed
    @IBAction func reset() {
        
        self.sketchLayer.clear()
        
        // Remove all graphics from the graphics layer
        self.graphicsLayer.removeAllGraphics()
        // Reset the distance
        self.currentDistance = 0
        
        //Start sketching again
        self.enableSketching()
    }
    
    // The addSketch action gets called when the add button is pressed
    @IBAction func addSketch() {
    
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        //Add a new graphic to the graphics layer
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol: nil, attributes: nil)
        self.graphicsLayer.addGraphic(graphic)
        
        
        self.sketchLayer.clear()
        
        // Reset the distance
        self.currentDistance = 0
        
        // Start sketching again
        self.enableSketching()
        
    }
}
