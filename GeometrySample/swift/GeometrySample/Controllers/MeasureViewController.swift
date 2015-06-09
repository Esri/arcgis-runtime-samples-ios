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

let kUnitSelectorSegue = "UnitSelectorSegue"

class MeasureViewController: UIViewController, AGSMapViewLayerDelegate, UnitSelectorViewDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var toolbar:UIToolbar!
    @IBOutlet weak var measureMethod:UISegmentedControl!
    @IBOutlet weak var redoButton:UIBarButtonItem!
    @IBOutlet weak var undoButton:UIBarButtonItem!
    @IBOutlet weak var resetButton:UIBarButtonItem!
    @IBOutlet weak var userInstructions:UILabel!
    @IBOutlet weak var selectUnitButton:UIButton!
    
    var sketchLayer:AGSSketchGraphicsLayer!
    var distance:Double!
    var area:Double!
    var distanceUnit:AGSSRUnit!
    var areaUnit:AGSAreaUnits!
    var popOverController:UIPopoverController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.showMagnifierOnTapAndHold = true
        self.mapView.enableWrapAround()
        self.mapView.layerDelegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        self.userInstructions.text = "Sketch on the map to measure distance or area"
        
        // Register for geometry changed notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"respondToGeomChanged:", name:AGSSketchGraphicsLayerGeometryDidChangeNotification, object:nil)
        
        self.selectUnitButton.backgroundColor = UIColor.clearColor()
        
        // Set the default measures and units
        self.distance = 0
        self.area = 0
        self.distanceUnit = .UnitSurveyMile
        self.areaUnit = .Acres
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapView delegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        // Create and add a sketch layer to the map
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch layer")
        self.mapView.touchDelegate = self.sketchLayer
    }
    
    func respondToGeomChanged(notification:NSNotification) {
    
        // Enable/Disable redo, undo, and add buttons
        self.undoButton.enabled = self.sketchLayer.undoManager.canUndo
        self.redoButton.enabled = self.sketchLayer.undoManager.canRedo
        self.resetButton.enabled = !self.sketchLayer.geometry.isEmpty() && self.sketchLayer.geometry != nil
        
        //return if we don't have a valid geometry yet
        //polyline must have atleast 2 vertices, polygon must have atleast 3
        let sketchGeometry = self.sketchLayer.geometry
        if !sketchGeometry.isValid() {
            return
        }
        
        // Update the distance and area whenever the geometry changes
        if sketchGeometry is AGSMutablePolyline {
            self.updateDistance(self.distanceUnit)
        }
        else if sketchGeometry is AGSMutablePolygon {
            self.updateArea(self.areaUnit)
        }
    }
    
    
    func updateDistance(unit: AGSSRUnit) {
    
        // Get the sketch layer's geometry
        let sketchGeometry = self.sketchLayer.geometry
        let geometryEngine = AGSGeometryEngine()
        
        // Get the geodesic distance of the current line
        self.distance = geometryEngine.geodesicLengthOfGeometry(sketchGeometry, inUnit:self.distanceUnit)
    
        // Display the current unit
        var distanceUnitString:String
        switch self.distanceUnit! {
        case AGSSRUnit.UnitSurveyMile:
            distanceUnitString = "Miles"
        case AGSSRUnit.UnitSurveyYard:
            distanceUnitString = "Yards"
        case AGSSRUnit.UnitSurveyFoot:
            distanceUnitString = "Feet"
        case AGSSRUnit.UnitKilometer:
            distanceUnitString = "Kilometers"
        case AGSSRUnit.UnitMeter:
            distanceUnitString = "Meters"
        default:
            distanceUnitString = ""
        }
        
        self.userInstructions.text = String(format: "%.0f", self.distance)
        self.selectUnitButton.setTitle(distanceUnitString, forState:.Normal)
    }
    
    func updateArea(unit:AGSAreaUnits) {
    
        // Get the sketch layer's geometry
        let sketchGeometry = self.sketchLayer.geometry
        let geometryEngine = AGSGeometryEngine()
        
        // Get the area of the current polygon
        self.area = geometryEngine.shapePreservingAreaOfGeometry(sketchGeometry, inUnit:self.areaUnit)
        
        // Display the current unit
        var areaUnitString:String!
        switch self.areaUnit! {
        case .SquareMiles:
            areaUnitString = "Square Miles"
        case .Acres:
            areaUnitString = "Acres"
        case .SquareYards:
            areaUnitString = "Square Yards"
        case .SquareKilometers:
            areaUnitString = "Square Kilometers"
        case .SquareMeters:
            areaUnitString = "Square Meters"
        default:
            break
        }
        
        self.userInstructions.text = String(format: "%.0f", self.area)
        self.selectUnitButton.setTitle(areaUnitString, forState:.Normal)
    }
    
    @IBAction func measure(measureMethod:UISegmentedControl) {
    
        // Set the geometry of the sketch layer to match the selected geometry
        if measureMethod.selectedSegmentIndex == 0 {
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        }
        else {
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        }
    }
    
    //MARK: - UnitSelectorViewControllerDelegate methods
    
    // Delegate method called by UnitSelectorViewController to update the distance unit
    func didSelectAreaUnit(unit:AGSAreaUnits) {
        self.areaUnit = unit
        self.updateArea(unit)
        self.dismissPopOver()
    }
    
    // Delegate method called by UnitSelectorViewController to update the area units
    func didSelectDistanceUnit(unit:AGSSRUnit) {
        self.distanceUnit = unit
        self.updateDistance(unit)
        self.dismissPopOver()
    }
    
    //MARK: - actions
    
    @IBAction func reset() {
        self.userInstructions.text = "Sketch on the map to measure distance or area"
        self.sketchLayer.clear()
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
    
    func dismissPopOver() {
        self.popOverController.dismissPopoverAnimated(true)
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kUnitSelectorSegue {
            self.popOverController = (segue as! UIStoryboardPopoverSegue).popoverController
            let controller = segue.destinationViewController as! UnitSelectorViewController
            controller.useAreaUnits = (self.measureMethod.selectedSegmentIndex == 0) ? false : true
            
            controller.delegate = self
        }
    }
}
