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

class BufferViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var bufferButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var geometrySelect:UISegmentedControl!
    @IBOutlet weak var slider:UISlider!
    @IBOutlet weak var distance:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    
    var graphicsLayer: AGSGraphicsLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    var lastBuffer:[AGSGraphic]!
    
    var bufferDistance:Int!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
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
        
        // Set the bounds of the slider and the initial value
        self.slider.minimumValue = 0
        self.slider.maximumValue = 5000
        self.slider.value = 3000
        
        let value = Int(self.slider.value)
        self.bufferDistance = value
        
        // Display the distance via the title of the bar button item
        self.distance.title = "\(value)m"
        
        // Create an envelope and zoom to it
        let sr = AGSSpatialReference(WKID: 102100)
        let envelope = AGSEnvelope(xmin: -8139237.214629, ymin:5016257.541842, xmax: -8090341.387563, ymax:5077377.325675, spatialReference:sr)
        self.mapView.zoomToEnvelope(envelope, animated:true)
        
        self.userInstructions.text = "Sketch a geometry and tap the buffer button to see the result"
        self.lastBuffer = [AGSGraphic]()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        // Create a sketch layer and add it to the map
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        self.mapView.touchDelegate = self.sketchLayer
    }
    
    //MARK: - Toolbar actions
    
    @IBAction func buffer() {
        self.userInstructions.text = "Reset or add another geometry"
        
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        // A symbol for points on the graphics layer
        let pointSymbol = AGSSimpleMarkerSymbol()
        pointSymbol.color = UIColor.yellowColor()
        pointSymbol.style = .Circle
        
        //A symbol for lines on the graphics layer
        let lineSymbol = AGSSimpleLineSymbol()
        lineSymbol.color = UIColor.yellowColor()
        lineSymbol.width = 4
        
        
        // Create the graphic and assign it the correct symbol according to its geometry type
        // Note: Lines and polygons are symbolized with the simple line symbol here
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol: nil, attributes: nil)
        
        if (sketchGeometry is AGSPoint) {
            graphic.symbol = pointSymbol
        }
        else {
            graphic.symbol = lineSymbol
        }
        
        
        //Add a new graphic to the graphics layer
        self.graphicsLayer.addGraphic(graphic)
        
        // A symbol for the buffer
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline.color = UIColor.darkGrayColor()
        
        // Create the buffer graphics using the geometry engine
        let geometryEngine = AGSGeometryEngine()
        let newGeometry = geometryEngine.bufferGeometry(sketchGeometry, byDistance:Double(self.bufferDistance))
        let newGraphic = AGSGraphic(geometry: newGeometry, symbol: innerSymbol, attributes: nil)
        
        self.lastBuffer.append(newGraphic)
        
        self.graphicsLayer.addGraphic(newGraphic)
        
        
        self.sketchLayer.clear()
    }
    
    
    
    @IBAction func selectGeometry(geomControl:UISegmentedControl) {
        
        // Set the geometry of the sketch layer to match the selected geometry
        switch geomControl.selectedSegmentIndex {
        case 0:
            self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        case 1:
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        case 2:
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        default:
            break
        }
        
        self.sketchLayer.clear()
    }
    
    
    @IBAction func sliderValueChanged(slider:UISlider) {
    
        // Get the value of the slider and update
        let value = Int(slider.value)
        self.bufferDistance = value
        self.distance.title = "\(value)m"
        
        // A symbol for the buffer
        let innerSymbol = AGSSimpleFillSymbol()
        innerSymbol.color = UIColor.redColor().colorWithAlphaComponent(0.40)
        innerSymbol.outline.color = UIColor.darkGrayColor()
        
        // Remove old buffers
        for oldGraphic in self.lastBuffer as [AGSGraphic] {
            self.graphicsLayer.removeGraphic(oldGraphic)
        }
        
        // Create the buffer graphics using the geometry engine
        var newGraphics = [AGSGraphic]()
        for graphic in self.graphicsLayer.graphics {
            let geometryEngine = AGSGeometryEngine()
            let newGeometry = geometryEngine.bufferGeometry(graphic.geometry, byDistance:Double(self.bufferDistance))
            let newGraphic = AGSGraphic(geometry: newGeometry, symbol:innerSymbol, attributes:nil)
            newGraphics.append(newGraphic)
        }
        
        // Remember the buffer graphics so we can remove them
        self.lastBuffer = newGraphics;
        
        // Add the buffer graphics to the graphics layer and notify it of the change
        self.graphicsLayer.addGraphics(newGraphics)
    }
    
    @IBAction func reset() {
        self.userInstructions.text = "Sketch a geometry and tap the buffer button to see the result"
        self.lastBuffer = [AGSGraphic]()
        self.graphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
    }
    
}
