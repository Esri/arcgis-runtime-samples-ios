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

class CutterViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var polygonButton:UIBarButtonItem!
    @IBOutlet weak var cutButton:UIBarButtonItem!
    @IBOutlet weak var drawButton:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    
    var graphicsLayer:AGSGraphicsLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.showMagnifierOnTapAndHold = true
        self.mapView.enableWrapAround()
        self.mapView.layerDelegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        // Create a graphics layer and add it to the map
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        self.polygonButton.enabled = false
        self.cutButton.enabled = false
        self.drawButton.enabled = false
        
        self.userInstructions.text = "Tap on the map to sketch a polygon"
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
        
        self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
    }
    
    //MARK: - Actions
    
    @IBAction func add() {
    
        self.drawButton.enabled = true
        self.cutButton.enabled = true
        
        self.userInstructions.text = "Tap the line button and sketch a line crossing the polygon"
        
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        //Create the graphic and add it to the graphics layer
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol:nil, attributes:nil)
        
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline = nil
        
        
        //A composite symbol for geometries on the graphics layer
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(innerSymbol)
        graphic.symbol = compositeSymbol
        
        self.graphicsLayer.addGraphic(graphic)
        self.sketchLayer.clear()
    }
    
    
    @IBAction func reset() {
    
        self.userInstructions.text = "Tap on the map to sketch a polygon"
        
        self.polygonButton.enabled = false
        self.addButton.enabled = true
        self.drawButton.enabled = true
        self.cutButton.enabled = false
        
        self.graphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
        
        // Reset the sketch layer's geometry to a polygon
        self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
    
    }
    
    @IBAction func polygon() {
    
        self.userInstructions.text = "Tap on the map to sketch a polygon";
        
        self.polygonButton.enabled = false
        self.addButton.enabled = true
        self.cutButton.enabled = false
        self.drawButton.enabled = true
        
        self.sketchLayer.clear()
        
        // Set the sketch layer's geometry to a polygon
        self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
    }
        
    @IBAction func line() {
        self.polygonButton.enabled = true
        self.addButton.enabled = false
        self.drawButton.enabled = false
        self.cutButton.enabled = true
        
        self.userInstructions.text = "Tap the cut button to cut the polygon with the polyline"
        
        // Set the sketch layer's geometry to a line
        self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
    }
    
    
    @IBAction func cut() {
        
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.redColor()
        lineSymbol.width = 4
        
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.blueColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline = nil
        
        // A composite symbol for the new geometry
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(innerSymbol)
        
        let geometryEngine = AGSGeometryEngine()
        
        // Create the new geometries using the geometry engine to cut the old ones by the cutter
        var newGraphics = [AGSGraphic]()
        if self.sketchLayer.geometry is AGSPolyline {
            for graphic in self.graphicsLayer.graphics as! [AGSGraphic] {
                let newGeometries = geometryEngine.cutGeometry(graphic.geometry, withCutter:self.sketchLayer.geometry as! AGSPolyline)
                
                // If the cut was succesful create a graphic and add it to the map
                if newGeometries.count != 0 {
                    for geometry in newGeometries as! [AGSGeometry] {
                        let newGraphic = AGSGraphic(geometry: geometry, symbol:compositeSymbol, attributes:nil)
                        newGraphics.append(newGraphic)
                    }
                }
                else {
                    newGraphics.append(graphic)
                }
            }
        
            self.sketchLayer.clear()
            
            self.graphicsLayer.removeAllGraphics()
            self.graphicsLayer.addGraphics(newGraphics)
        }
    }
}
