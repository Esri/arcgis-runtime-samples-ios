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

class OffsetViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var toolbar1:UIToolbar!
    @IBOutlet weak var toolbar2:UIToolbar!
    @IBOutlet weak var segmentedControl:UISegmentedControl!
    @IBOutlet weak var distanceSlider:UISlider!
    @IBOutlet weak var bevelSlider:UISlider!
    @IBOutlet weak var distance:UIBarButtonItem!
    @IBOutlet weak var bevel:UIBarButtonItem!
    @IBOutlet weak var geometrySelect:UISegmentedControl!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var offsetButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    @IBOutlet weak var mapView:AGSMapView!
    
    var sketchLayer:AGSSketchGraphicsLayer!
    var graphicsLayer:AGSGraphicsLayer!
    var lastOffset:[AGSGraphic]!
    var offsetDistance:Double!
    var bevelRatio:Double!
    var offsetType:AGSGeometryOffsetType!
    
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
        // this layer will hold the orginal geometries and the offset results
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Result Layer")
        
        // Set the bounds of the slider for distance and the initial value
        // Represents the amount by which we want to offset geometries
        self.distanceSlider.minimumValue = -2000
        self.distanceSlider.maximumValue = 2000
        self.distanceSlider.value = 1000
        
        let distValue = Double(self.distanceSlider.value)
        self.offsetDistance = distValue
        
        // Display the distance via the title of the bar button item
        self.distance.title = "\(Int(distValue))m"
        
        // Set the bounds of the slider for bevel ratio and the initial value
        self.bevelSlider.minimumValue = 0
        self.bevelSlider.maximumValue = 3
        self.bevelSlider.value = 0.5
        
        let bevelValue = Double(self.bevelSlider.value)
        self.bevelRatio = bevelValue
        
        // Display the bevel ratio via the title of the bar button item
        self.bevel.title = String(format: "%.6fm", bevelValue)
        
        self.offsetType = .Mitered
        
        // Create an envelope and zoom to it
        let sr = AGSSpatialReference(WKID: 102100)
        let envelope = AGSEnvelope(xmin: -8139237.214629, ymin:5016257.541842, xmax: -8090341.387563, ymax:5077377.325675, spatialReference:sr)
        self.mapView.zoomToEnvelope(envelope, animated:true)
        
        self.userInstructions.text = "Sketch a geometry and tap the offset button to see the result"
        
        self.lastOffset = [AGSGraphic]()
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
    
    @IBAction func offsetType(control:UISegmentedControl) {
        
        //Set the offset type to match the selected offset type
        switch (control.selectedSegmentIndex) {
        case 0:
            self.offsetType = .Mitered
            break;
        case 1:
            self.offsetType = .Rounded
            break;
        case 2:
            self.offsetType = .Square
            break;
        case 3:
            self.offsetType = .Bevelled
            
        default:
            break
        }
        
        self.updateOffset()
    }
    
    
    @IBAction func offset() {
    
        self.userInstructions.text = "Adjust distance and bevel ratio, tap reset to start over"
        
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        //A symbol for lines on the graphics layer
        let sketchLineSymbol = AGSSimpleLineSymbol()
        sketchLineSymbol.color = UIColor.redColor()
        sketchLineSymbol.width = 4
        
        // Create the graphic and assign it the correct symbol according to its geometry type
        // Note: Lines and polygons are symbolized with the simple line symbol here
        let graphic = AGSGraphic(geometry: sketchGeometry, symbol:sketchLineSymbol, attributes:nil)
        
        //Add a new graphic to the graphics layer
        self.graphicsLayer.addGraphic(graphic)
        
        // Symbol for the offset
        let offsetLineSymbol = AGSSimpleLineSymbol()
        offsetLineSymbol.color = UIColor.blueColor()
        offsetLineSymbol.width = 4
        
        let geometryEngine = AGSGeometryEngine()
        let offsetGeometry = geometryEngine.offsetGeometry(sketchGeometry, byDistance:self.offsetDistance, withJointType:self.offsetType, bevelRatio:self.bevelRatio, flattenError:0)
        let offsetGraphic = AGSGraphic(geometry: offsetGeometry, symbol:offsetLineSymbol, attributes:nil)
        
        self.lastOffset.append(offsetGraphic)
        
        self.graphicsLayer.addGraphic(offsetGraphic)
        
        self.sketchLayer.clear()
    }
    
    func updateOffset() {
        // Remove old graphics
        for oldGraphic in self.lastOffset {
            self.graphicsLayer.removeGraphic(oldGraphic)
        }
        
        // Symbol for the offset
        let offsetLineSymbol = AGSSimpleLineSymbol()
        offsetLineSymbol.color = UIColor.blueColor()
        offsetLineSymbol.width = 4
        
        // Create the offset graphics using the geometry engine
        var newGraphics = [AGSGraphic]()
        for graphic in self.graphicsLayer.graphics {
            let geometryEngine = AGSGeometryEngine()
            let newGeometry = geometryEngine.offsetGeometry(graphic.geometry, byDistance:self.offsetDistance, withJointType:self.offsetType, bevelRatio:self.bevelRatio, flattenError:0)
            let newGraphic = AGSGraphic(geometry: newGeometry, symbol:offsetLineSymbol, attributes:nil)
            newGraphics.append(newGraphic)
        }
        
        // Remember the offset graphics so we can remove them
        self.lastOffset = newGraphics
        
        // Add the offset graphics to the graphics layer and notify it of the change
        self.graphicsLayer.addGraphics(newGraphics)
    
    }
    
    @IBAction func selectGeometry(geomControl: UISegmentedControl) {
        
        // Set the geometry of the sketch layer to match the selected geometry
        switch geomControl.selectedSegmentIndex {
        case 0:
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        case 1:
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        default:
            break
        }
        self.sketchLayer.clear()
    }
    
    @IBAction func distanceSliderValueChanged(slider:UISlider) {
    
        // Get the value of the slider and update
        let value = Double(slider.value)
        self.offsetDistance = value
        self.distance.title = "\(Int(value))m"
        
        self.updateOffset()
    }
    
    @IBAction func bevelSliderValueChanged(slider:UISlider) {
    
        // Get the value of the slider and update
        let value = Double(slider.value)
        self.bevelRatio = value
        self.bevel.title = String(format: "%.6fm", value)
        
        self.updateOffset()
    }
    
    @IBAction func reset() {
        self.userInstructions.text = "Sketch a geometry and tap the offset button to see the result"
        self.lastOffset = [AGSGraphic]()
        self.graphicsLayer.removeAllGraphics()
        self.sketchLayer.clear()
    }
}
