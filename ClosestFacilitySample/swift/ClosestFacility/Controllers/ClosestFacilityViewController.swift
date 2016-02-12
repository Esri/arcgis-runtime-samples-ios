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
//

import UIKit
import ArcGIS

let kBaseMap = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
let kFacilitiesLayerURL = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Louisville/LOJIC_PublicSafety_Louisville/MapServer/1"

let kCFTask = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Closest%20Facility"

let kSettingsSegueName = "SettingsSegue"

class ClosestFacilityViewController: UIViewController, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSCalloutDelegate, AGSClosestFacilityTaskDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var statusMessageLabel:UILabel!
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var clearSketchButton:UIBarButtonItem!
    @IBOutlet weak var findCFButton:UIBarButtonItem!
    @IBOutlet weak var sketchModeSegCtrl:UISegmentedControl!
    
    var facilitiesLayer:AGSFeatureLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    var selectedGraphic:AGSGraphic!
    var graphicsLayer:AGSGraphicsLayer!
    var cfTask:AGSClosestFacilityTask!
    var cfOp:NSOperation!
    var settingsViewController:SettingsViewController!
    var numIncidents:Int = 0
    var numBarriers:Int = 0
    var deleteCalloutView:UIView!
    
    var parameters:Parameters!
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Add the basemap - the tiled layer
        let mapUrl = NSURL(string: kBaseMap)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Zooming to an initial envelope with the specified spatial reference of the map.
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -9555545.779983964, ymin:4593330.340739982, xmax:-9531085.930932742, ymax:4628491.373751115,
        spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        //important step in detecting the touch events on the map
        self.mapView.touchDelegate = self
        
        //step to call the mapViewDidLoad method to do the initiation of Closest Facility Task.
        self.mapView.layerDelegate = self
        
        
        //add  graphics layer for showing results of the closest facility analysis
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"ClosestFacility")
        
        // set the callout delegate so we can display callouts
        // updated the callout to the map instead of the layer.
        self.mapView.callout.delegate = self
        
        
        //creating the facilities (fire stations) layer
        self.facilitiesLayer = AGSFeatureLayer(URL: NSURL(string: kFacilitiesLayerURL), mode: .Snapshot)
        
        //specifying the symbol for the fire stations.
        let renderer = AGSSimpleRenderer(symbol: AGSPictureMarkerSymbol(imageNamed: "FireStation"))
        self.facilitiesLayer.renderer = renderer
        self.facilitiesLayer.outFields = ["*"]
        
        //adding the fire stations feature layer to the map view.
        self.mapView.addMapLayer(self.facilitiesLayer, withName:"Facilities")
        
//        // add sketch layer to the map
//        let mp = AGSMutablePoint(spatialReference: AGSSpatialReference.webMercatorSpatialReference())
//        self.sketchLayer = AGSSketchGraphicsLayer(geometry: mp)
//        self.mapView.addMapLayer(self.sketchLayer, withName:"sketchLayer")
//        
//        //Register for "Geometry Changed" notifications
//        //We want to enable/disable UI elements when sketch geometry is modified
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "respondToGeomChanged:", name: AGSSketchGraphicsLayerGeometryDidChangeNotification, object: nil)
//        
////        // set the mapView's touchDelegate to the sketchLayer so we get points symbolized when sketching
//        self.mapView.touchDelegate = self.sketchLayer
        
        // create a custom callout view using a button with an image
        // this is to remove incidents and barriers after we add them to the map
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
        let deleteBtn = UIButton(type: .Custom)
        deleteBtn.frame = CGRect(x: 8, y: 0, width: 24, height: 24)
        deleteBtn.setImage(UIImage(named: "remove24.png"), forState:.Normal)
        deleteBtn.addTarget(self, action: "removeIncidentBarrierClicked", forControlEvents: .TouchUpInside)
        customView.addSubview(deleteBtn)
        self.deleteCalloutView = customView
        
        //instantiate the parameters object
        self.parameters = Parameters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
       
        // add sketch layer to the map
        let mp = AGSMutablePoint(spatialReference: AGSSpatialReference.webMercatorSpatialReference())
        self.sketchLayer = AGSSketchGraphicsLayer(geometry: mp)
        self.mapView.addMapLayer(self.sketchLayer, withName:"sketchLayer")
        
        //Register for "Geometry Changed" notifications
        //We want to enable/disable UI elements when sketch geometry is modified
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "respondToGeomChanged:", name: AGSSketchGraphicsLayerGeometryDidChangeNotification, object: nil)
        
         //set the mapView's touchDelegate to the sketchLayer so we get points symbolized when sketching
        self.mapView.touchDelegate = self.sketchLayer
        
        //set up the cf task
        self.cfTask = AGSClosestFacilityTask(URL: NSURL(string: kCFTask))
        self.cfTask.delegate = self //required to respond to the cf task.
    }
    
    
    //MARK: - AGSCalloutDelegate
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        
        let graphic = feature as! AGSGraphic
        let incidentNum = graphic.attributeAsStringForKey("incidentNumber")
        let barrierNum = graphic.attributeAsStringForKey("barrierNumber")
        
        self.selectedGraphic = graphic
        if self.sketchLayer != nil {
            self.sketchLayer.clear()
        }
        
        if incidentNum != nil || barrierNum != nil {
            self.mapView.callout.customView = self.deleteCalloutView
            return true
        }
        else{
            return false
        }
    }
    
    //MARK: - AGSClosestFacilityTaskDelegate
    
    //if the solveClosestFacilityWithResult operation completed successfully
    func closestFacilityTask(closestFacilityTask: AGSClosestFacilityTask!, operation op: NSOperation!, didSolveClosestFacilityWithResult closestFacilityTaskResult: AGSClosestFacilityTaskResult!) {
        
        //remove previous graphics from the graphics layer
        //if "barrierNumber" exists in the attributes, we know it is a barrier graphic
        //if "incidentNumber" exists in the attributes, we know it is an incident graphic
        //so leave that graphic and go to the next one
        //careful not to attempt to mutate the graphics array while
        //it is being enumerated
        let graphics = self.graphicsLayer.graphics
        for g in graphics as! [AGSGraphic] {
            if !(g.attributeAsStringForKey("barrierNumber") == nil ||
                g.attributeAsStringForKey("incidentNumber") == nil) {
                self.graphicsLayer.removeGraphic(g)
            }
        }
    
        //iterate through the closest facility results array in the closestFacilityTaskResult returned by the task
        for cfResult in closestFacilityTaskResult.closestFacilityResults as! [AGSClosestFacilityResult] {
            //symbolize the returned route graphic
            cfResult.routeGraphic.symbol = self.routeSymbol()
            
            //add the route graphic to the graphics layer
            self.graphicsLayer.addGraphic(cfResult.routeGraphic)
        }
        
        //stop activity indicator
//        SVProgressHUD.dismiss()
        
        //changing the status message label.
        self.statusMessageLabel.text = "Tap reset to start over"
        
        //zoom to graphics layer extent
        let env = self.graphicsLayer.fullEnvelope as! AGSMutableEnvelope
        env.expandByFactor(1.2)
        self.mapView.zoomToEnvelope(env, animated:true)
    }
    
    //if error encountered while executing cf task
    func closestFacilityTask(closestFacilityTask: AGSClosestFacilityTask!, operation op: NSOperation!, didFailSolveWithError error: NSError!) {
        //stop activity indicator
//        SVProgressHUD.dismiss()
        
        //show error message
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func closestFacilityTask(closestFacilityTask: AGSClosestFacilityTask!, operation op: NSOperation!, didRetrieveDefaultClosestFacilityTaskParameters closestFacilityParams: AGSClosestFacilityTaskParameters!) {
        
        //specify some custom parameters
        
        //Number of facilities to be returned
        closestFacilityParams.defaultTargetFacilityCount = self.parameters.facilityCount
        
        //The kind of the cuttoff attribute - Time, Length etc. We are using Time
        closestFacilityParams.impedanceAttributeName = "Time"
        //Specify the cuttoff travelling time to the facility. In minutes.
        closestFacilityParams.defaultCutoffValue = self.parameters.cutoffTime
        
        //Specify the travel direction.
        closestFacilityParams.travelDirection = AGSNATravelDirection.FromFacility
        
        //specifying the spatial reference output
        closestFacilityParams.outSpatialReference = self.mapView.spatialReference
        
        //setting the incidents for the CF task. We have only one here - the tapped location.
        
        var incidents = [AGSGraphic]()
        var polygonBarriers = [AGSGraphic]()
        
        // get the incidents, barriers for the cf task
        for g in self.graphicsLayer.graphics as! [AGSGraphic] {
            // if it's a incident graphic, add the object to incidents
            if g.attributeAsStringForKey("incidentNumber") != nil {
                incidents.append(g)
            }
            
            // if "barrierNumber" exists in the attributes, we know it is a barrier
            // so add the object to our barriers
            else if g.attributeAsStringForKey("barrierNumber") != nil {
                polygonBarriers.append(g)
            }
        }
        
        // set the incidents and polygon barriers on the parameters object
        if incidents.count > 0 {
            closestFacilityParams.setIncidentsWithFeatures(incidents)
        }
        
        if polygonBarriers.count > 0 {
            closestFacilityParams.setPolygonBarriersWithFeatures(polygonBarriers)
        }
        
        //specify the features that need to be used as the facilities. We use the fire stations layer features.
        closestFacilityParams.setFacilitiesWithFeatures(self.facilitiesLayer.graphics)
        
        //calls the solveClosestFacilityWithParameters with modified params. 
        self.cfOp = self.cfTask.solveClosestFacilityWithParameters(closestFacilityParams)
    }
    
    func closestFacilityTask(closestFacilityTask: AGSClosestFacilityTask!, operation op: NSOperation!, didFailToRetrieveDefaultClosestFacilityTaskParametersWithError error: NSError!) {
        //stop activity indicator
//        SVProgressHUD.dismiss()
        
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    //MARK: - Action Methods
    
    // reset button clicked
    @IBAction func resetBtnClicked(sender:AnyObject) {
        self.reset()
    }
    
    //
    // add a incident or barrier depending on the sketch layer's current geometry
    //
    @IBAction func addIncidentOrBarrier(sender:AnyObject) {
        
        //grab the geometry, then clear the sketch
        let geometry : AGSGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        self.sketchLayer.clear()
        //Prepare symbol and attributes for the Incident/Barrier
        var attributes = [String:AnyObject]()
        var symbol:AGSSymbol!
        var g:AGSGraphic!
        
        switch (AGSGeometryTypeForGeometry(geometry)) {
        //Incident
        case .Point:
            self.numIncidents++
            //ading an attribute for the incident graphic
            attributes["incidentNumber"] = self.numIncidents
            
            //getting the symbol for the incident graphic
            symbol = self.incidentSymbol()
            g = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
            
            //You can set additional properties on the incident here
            self.graphicsLayer.addGraphic(g)
            //enable the findFCButton
            self.findCFButton.enabled = true
        
        //Barrier
        case .Polygon:
            self.numBarriers++
            attributes["barrierNumber"] = self.numBarriers
            //getting the symbol for the incident graphic
            symbol = self.barrierSymbol()
            g = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
            self.graphicsLayer.addGraphic(g)
        default:
            break
        }
    
    }
    
    //
    // if our segment control was changed, then the sketch layer geometry needs to
    // be updated to reflect that (point for incidents and polygon for barriers)
    //
    @IBAction func incidentsBarriersValChanged(segCtrl:UISegmentedControl) {
        
        if self.sketchLayer == nil {
            return
        }
        
        switch (segCtrl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.clear()
        
            //geometry for sketching incident points
            self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)

        case 1:
            self.sketchLayer.clear()
            
            //geometry for sketching barrier polygons
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        
        default:
            break
        }
    }
    
    
    // perform the cf task's retrieve default parameters operation
    @IBAction func findCFButtonClicked(sender:AnyObject) {
        
        // update the status message
        self.statusMessageLabel.text = "Finding closest facilities"
        
        // if we have a sketch layer on the map, remove it
        if self.sketchLayer != nil {
            let layers = self.mapView.mapLayers as! [AGSLayer]
            if layers.contains(self.sketchLayer) {
                self.mapView.removeMapLayerWithName(self.sketchLayer.name)
                self.mapView.touchDelegate = nil
                self.sketchLayer = nil
                
                //also disable the sketch control so that user cannot sketch
                self.sketchModeSegCtrl.selectedSegmentIndex = -1
                for (var i = 0 ; i < self.sketchModeSegCtrl.numberOfSegments; i++) {
                    self.sketchModeSegCtrl.setEnabled(false, forSegmentAtIndex: i)
                }
            }
        }
    
        //retrieves the default parameters for the closest facility task from the server
        //the caOp property will keep tract of the operation in case we need to cancel it at any point.
        self.cfOp = self.cfTask.retrieveDefaultClosestFacilityTaskParameters()
        
//        SVProgressHUD.showWithStatus("Search for closest facilities")

    }
    
    // clear the sketch layer
    @IBAction func clearSketchLayer(sender:AnyObject) {
        self.sketchLayer.clear()
    }
    
    @IBAction func resetButttonClicked(sender:AnyObject) {
        self.reset()
    }
    
    //MARK: - Helper Methods
    
    func respondToGeomChanged(notification:NSNotification) {
        //Enable/disable UI elements appropriately
        self.addButton.enabled = self.sketchLayer.geometry.isValid()
        self.clearSketchButton.enabled = !self.sketchLayer.geometry.isEmpty()
    }
    
    
    // reset the sample so we can perform another analysis
    func reset() {
    
        // set incident counter back to 0
        self.numIncidents = 0
        
        // set barrier counter back to 0
        self.numBarriers = 0
        
        // remove all graphics
        self.graphicsLayer.removeAllGraphics()
        
        // reset sketchModeSegCtrl to point
        self.sketchModeSegCtrl.selectedSegmentIndex = 0
        for (var i = 0; i < self.sketchModeSegCtrl.numberOfSegments; i++) {
            self.sketchModeSegCtrl.setEnabled(true, forSegmentAtIndex: i)
        }
        
        //disable the findCFButton
        self.findCFButton.enabled = false
        
        // reset directions label
        self.statusMessageLabel.text = "Tap on the map to create incidents"
        
        // if the sketch layer was removed/nil'd out, re-add it
        if self.sketchLayer == nil {
            var geometry:AGSGeometry!
            if self.sketchModeSegCtrl.selectedSegmentIndex == 0 {
                geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
            }
            else {
                geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
            }
            self.sketchLayer = AGSSketchGraphicsLayer(geometry: geometry)
            self.mapView.insertMapLayer(self.sketchLayer, withName:"sketchLayer", atIndex:1)
            self.mapView.touchDelegate = self.sketchLayer
        }
        else {
            // clear the sketch layer and reset it to a point
            self.sketchLayer.clear()
        }
        
        self.statusMessageLabel.text = "Add incidents and barriers"
    }
    
    func removeIncidentBarrierClicked() {
    
        //redunce the incident number is the removed item is an incident point
        if let _ = self.selectedGraphic.attributeAsStringForKey("incidentNumber") {
            self.numIncidents--
            if self.numIncidents == 0 {
                //disable the findCFButton
                self.findCFButton.enabled = false
            }
        }
        
        //redunce the barrier number is the removed item is a barrier polygon
        if let _ = self.selectedGraphic.attributeAsStringForKey("barrierNumber") {
            self.numBarriers--
        }
        
        //remove the selected graphic from the layer
        self.graphicsLayer.removeGraphic(self.selectedGraphic)
        
        //nil out the selected graphic property.
        self.selectedGraphic = nil
        
        // hide the callout
        self.mapView.callout.hidden = true
    }
    
    // create a composite symbol with a number
    func incidentSymbol() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        // create outline
        let sls = AGSSimpleLineSymbol()
        sls.color = UIColor.blackColor()
        sls.width = 2
        sls.style = .Solid
        cs.addSymbol(sls)
        
        // create main circle
        let sms = AGSSimpleMarkerSymbol()
        sms.color = UIColor.greenColor()
        sms.outline = sls
        sms.size = CGSizeMake(20, 20)
        sms.style = .Circle
        cs.addSymbol(sms)
        
        return cs
    }
    
    //generates the symbol for the routes.
    func routeSymbol() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        //the outline symbol
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor(red: 1.0, green:1.0, blue:1.0, alpha:0.5)
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        
        //the color of the route.
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor(red:0.3, green:0.3, blue:1.0, alpha:0.5)
        sls2.style = .Solid
        sls2.width = 4
        cs.addSymbol(sls2)
        
        return cs
    }
    
    // default symbol for the barriers
    //
    func barrierSymbol() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        let sls = AGSSimpleLineSymbol()
        sls.color = UIColor.redColor()
        sls.style = .Solid
        sls.width = 2
        
        let sfs = AGSSimpleFillSymbol()
        sfs.outline = sls
        sfs.style = .Solid
        sfs.color = UIColor.redColor().colorWithAlphaComponent(0.45)
        cs.addSymbol(sfs)
        
        return cs
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == kSettingsSegueName {
            let controller = segue.destinationViewController as! SettingsViewController
            controller.parameters = self.parameters
            
            //if ipad show formsheet
            if AGSDevice.currentDevice().isIPad() {
                controller.modalPresentationStyle = .FormSheet
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
