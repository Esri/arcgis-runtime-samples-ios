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

class DensifyViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var geometryControl:UISegmentedControl!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var slider:UISlider!
    @IBOutlet weak var distance:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    
    var resultGraphicsLayer:AGSGraphicsLayer!
    var sketchGeometries:[AGSGeometry]!
    var densifyDistance:Double!
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
        
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        let pointSymbol = AGSSimpleMarkerSymbol()
        pointSymbol.color = UIColor.redColor()
        pointSymbol.style = .Circle
        pointSymbol.size = CGSizeMake(5, 5)
        
        // A composite symbol for lines and polygons
        let compositeSymbol = AGSCompositeSymbol()
        compositeSymbol.addSymbol(lineSymbol)
        compositeSymbol.addSymbol(pointSymbol)
        
        // A renderer for the graphics layer
        let simpleRenderer = AGSSimpleRenderer(symbol: compositeSymbol)
        
        // Create a graphics layer and add it to the map.
        // This layer will contain the results of densify operation
        self.resultGraphicsLayer = AGSGraphicsLayer()
        self.resultGraphicsLayer.renderer = simpleRenderer
        self.mapView.addMapLayer(self.resultGraphicsLayer, withName:"Results Layer")
        
        // Set the limits and current value of the slider
        // Represents the amount by which we want to densify geometries
        self.slider.minimumValue = 1
        self.slider.maximumValue = 5000
        self.slider.value = 3000
        
        let value = Double(self.slider.value)
        self.densifyDistance = value
        self.distance.title = "\(Int(value))m"
        
        // Create an envelope and zoom the map to it
        let sr = AGSSpatialReference(WKID: 102100)
        let envelope = AGSEnvelope(xmin: -8139237.214629, ymin:5016257.541842, xmax: -8090341.387563, ymax:5077377.325675, spatialReference:sr)
        self.mapView.zoomToEnvelope(envelope, animated:true)
        
        self.userInstructions.text = "Sketch a geometry and tap the densify button to see the result"
        
        self.sketchGeometries = [AGSGeometry]()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        // Create a sketch layer and add it to the map
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        self.mapView.touchDelegate = self.sketchLayer
    }
    
    @IBAction func sliderValueChanged(slider:UISlider) {
        // Get the value of the slider
        // and densify the geometries using the new value
        let value = Double(slider.value)
        self.densifyDistance = value
        self.distance.title = "\(Int(value))m"
        
        self.resultGraphicsLayer.removeAllGraphics()
        
        var newGraphics = [AGSGraphic]()
        
        // Densify the geometries using the geometry engine
        for geometry in self.sketchGeometries as [AGSGeometry] {
            let geometryEngine = AGSGeometryEngine()
            
            let newGeometry = geometryEngine.densifyGeometry(geometry, withMaxSegmentLength:self.densifyDistance)
            let graphic = AGSGraphic(geometry: newGeometry, symbol:nil, attributes:nil)
            newGraphics.append(graphic)
        }
        
        self.resultGraphicsLayer.addGraphics(newGraphics)
    }
    
    @IBAction func selectGeometry(geomControl:UISegmentedControl) {
    
        // Set the geometry of the sketch layer to match
        // the selected geometry type (polygon or polyline)
        switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        case 1:
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        default:
            break
        }
        
        self.sketchLayer.clear()
    }
    
    @IBAction func reset() {
        self.userInstructions.text = "Sketch a geometry and tap the densify button to see the result";
        
        self.sketchGeometries = [AGSGeometry]()
        self.resultGraphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
    }
    
    
    @IBAction func densify() {
        
        self.userInstructions.text = "Adjust slider to see changes, tap reset to start over "
        
        // Get the sketch layer's geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        // Keep the original geometries to densify again later
        self.sketchGeometries.append(sketchGeometry)
        
        let geometryEngine = AGSGeometryEngine()
        
        // Densify the geometry and create a graphic to add to the result graphics layer
        let newGeometry = geometryEngine.densifyGeometry(sketchGeometry, withMaxSegmentLength:self.densifyDistance)
        let graphic = AGSGraphic(geometry: newGeometry, symbol:nil, attributes:nil)
        
        self.resultGraphicsLayer.addGraphic(graphic)
        self.sketchLayer.clear()
    }
}
