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

let kDefaultMap = "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
let kFacilitiesLayerURL = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Louisville/LOJIC_PublicSafety_Louisville/MapServer/1"
let kSATask = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Service%20Area"
let kSettingsSegueIdentifier = "SettingsSegue"

class ServiceAreaViewController: UIViewController, AGSMapViewTouchDelegate, AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSServiceAreaTaskDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var statusMessageLabel:UILabel!
    @IBOutlet weak var activitySegControl:UISegmentedControl!
    @IBOutlet weak var addBarrierButton:UIBarButtonItem!
    @IBOutlet weak var clearSketchButton:UIBarButtonItem!
    
    var facilitiesLayer:AGSFeatureLayer!
    var graphicsLayer:AGSGraphicsLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    var selectedGraphic:AGSGraphic!
    var saTask:AGSServiceAreaTask!
    var saOp:NSOperation!
    var barrierCalloutView:UIView!
    var facilitiesCalloutView:UIView!
    //used to contain the number of barriers on the map at one time.
    var numBarriers:Int = 0
    var parameters:Parameters!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapUrl = NSURL(string: kDefaultMap)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Zooming to an initial envelope with the specified spatial reference of the map.
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -9555545.779983964, ymin:4593330.340739982, xmax:-9531085.930932742, ymax:4628491.373751115, spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        //important step in detecting the touch events on the map
        self.mapView.touchDelegate = self
        
        //step to call the mapViewDidLoad method to do the initiation of Service Area Task.
        self.mapView.layerDelegate = self
        
        //set the mapView's callout Delegate so we can display callouts
        self.mapView.callout.delegate = self
        
        //add  graphics layer for showing results of the service area analysis
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"ServiceArea")
        
        
        //creating the fire stations layer
        self.facilitiesLayer = AGSFeatureLayer(URL: NSURL(string: kFacilitiesLayerURL), mode:.Snapshot)
        
        //specifying the symbol for the fire stations.
        let renderer = AGSSimpleRenderer(symbol: AGSPictureMarkerSymbol(imageNamed: "FireStation.png"))
        self.facilitiesLayer.renderer = renderer
        self.facilitiesLayer.outFields = ["*"]
        
        //adding the fire stations feature layer to the map view.
        self.mapView.addMapLayer(self.facilitiesLayer, withName:"Facilities")
        
        // create a custom callout view for barriers using a button with an image and a label
        // this is to remove barriers after we add them to the map
        let customView = UIView(frame: CGRectMake(0, 0, 150, 24))
        let removeBarrierButton = UIButton()
        removeBarrierButton.frame = CGRectMake(0, 0, 24, 24)
        removeBarrierButton.setImage(UIImage(named: "remove24.png"), forState:.Normal)
        removeBarrierButton.addTarget(self, action:"removeBarrierClicked", forControlEvents:.TouchUpInside)
        customView.addSubview(removeBarrierButton)
        
        //creating the label
        let removeBarrierLabel = UILabel()
        removeBarrierLabel.frame = CGRectMake(30, 0, 110, 24)
        removeBarrierLabel.backgroundColor = UIColor.clearColor()
        removeBarrierLabel.textColor = UIColor.redColor()
        removeBarrierLabel.text = "Delete Barrier"
        customView.addSubview(removeBarrierLabel)
        
        //assign the custom view as the callout view
        self.barrierCalloutView = customView
        
        // create a custom callout view for facilities using a button with a title
        // this is to find service area
        let customViewFacilities = UIView(frame: CGRectMake(0, 0, 150, 24))
        let findSAButton = UIButton(frame: CGRectMake(5, 0, 140, 24))
        findSAButton.setTitle("Find Service Area", forState:.Normal)
        findSAButton.addTarget(self, action:"findServiceArea", forControlEvents:.TouchUpInside)
        findSAButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        findSAButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        customViewFacilities.addSubview(findSAButton)
        
        //assign the custom view as the callout view
        self.facilitiesCalloutView = customViewFacilities
        
        //Register for "Geometry Changed" notifications
        //We want to enable/disable UI elements when sketch geometry is modified
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"respondToGeomChanged:", name:AGSSketchGraphicsLayerGeometryDidChangeNotification, object:nil)
        
        //instantiate a parameter object to feed values to the api
        self.parameters = Parameters()
        
        // initialize barrier counter
        self.numBarriers = 0
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {

        //set up the service area task
        self.saTask = AGSServiceAreaTask(URL: NSURL(string: kSATask))
        self.saTask.delegate = self //required to respond to the service area task.
    }
    
    //MARK: - AGSCalloutDelegate
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        
        let graphic = feature as! AGSGraphic
        
        //if the graphic that was tapped on belongs to the "Facilities" layer, show the callout without a custom view
        if graphic.layer!.name == "Facilities" {
            //we have to make sure that the sketch mode is not on.
            if self.sketchLayer == nil {
                self.selectedGraphic = graphic
                self.mapView.callout.customView = self.facilitiesCalloutView
                return true
            }
        }
        
        //if the graphic that was tapped on belongs to the graphics layer and that it is a barrier graphic, show the callout with a custom view
        else {
            //getting the barrier number from the attributes dictionary of the graphic
            if let _ = graphic.attributeAsStringForKey("barrierNumber") {
                
                //we have to make sure that the sketch mode is not on.
                if self.sketchLayer == nil {
                    self.selectedGraphic = graphic
                    
                    //assign the custom callout that we created earlier, to the barrier graphic's callout view.
                    self.mapView.callout.customView = self.barrierCalloutView
                    
                    //at this point, the sketch layer is cleared and the barrier is ready for deletion is required.
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    //MARK: - AGSServiceAreaTaskDelegate
    
    //if the solveServiceAreaTaskWithResult operation completed successfully
    func serviceAreaTask(serviceAreaTask: AGSServiceAreaTask!, operation op: NSOperation!, didSolveServiceAreaWithResult serviceAreaTaskResult: AGSServiceAreaTaskResult!) {
        
        //remove previous graphics from the graphics layer
        //if "barrierNumber" exists in the attributes, we know it is a barrier
        //so leave that graphic and go to the next one
        //careful not to attempt to mutate the graphics array while
        //it is being enumerated
        let graphics = self.graphicsLayer.graphics
        for g in graphics as! [AGSGraphic] {
            if g.attributeAsStringForKey("barrierNumber") == nil {
                self.graphicsLayer.removeGraphic(g)
            }
        }
        
        //iterate through the service area results array in the serviceAreaTaskResult returned by the task
        for (var i=0; i < serviceAreaTaskResult.serviceAreaPolygons.count; i++) {
            let saResultPolygon = serviceAreaTaskResult.serviceAreaPolygons[i] as! AGSGraphic
            //if the first one, it is the first time break polygon
            if i == 0 {
                saResultPolygon.symbol = self.serviceAreaSymbolBreak1() //get the appropriate symbol
            }
            
            //if the second one, it is the second time break polygon
            else {
                saResultPolygon.symbol = self.serviceAreaSymbolBreak2() //get the appropriate symbol
            }
            
            //add the service area graphic to the graphics layer
            self.graphicsLayer.addGraphic(saResultPolygon)
        }
        
        
        //stop activity indicator
        SVProgressHUD.dismiss()
        
        //hide the callout
        self.mapView.callout.hidden = true
        
        //zoom to service area graphics layer extent
        let env = self.graphicsLayer.fullEnvelope as! AGSMutableEnvelope
        env.expandByFactor(1.2)
        self.mapView.zoomToEnvelope(env, animated:true)
    }
    
    //if error encountered while executing sa task
    func serviceAreaTask(serviceAreaTask: AGSServiceAreaTask!, operation op: NSOperation!, didFailSolveWithError error: NSError!) {
        
        //stop activity indicator
        SVProgressHUD.dismiss()
        
        //show error message
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //if retrieveDefaultServiceAreaTaskParameters operation completed successfully
    func serviceAreaTask(serviceAreaTask: AGSServiceAreaTask!, operation op: NSOperation!, didRetrieveDefaultServiceAreaTaskParameters serviceAreaParams: AGSServiceAreaTaskParameters!) {
        
        //specify some custom parameters
        //The kind of the cuttoff attribute - Time, Length etc. We are using Time
        serviceAreaParams.impedanceAttributeName = "Time"
        
        //Specify the time breaks for the service area of the facility. In minutes.
        var breaks = [UInt]()
        //getting the breaks from the settingsViewController
        breaks.append(self.parameters.firstTimeBreak)
        breaks.append(self.parameters.secondTimeBreak)
        serviceAreaParams.defaultBreaks = breaks
        
        //adding some restrictions to the service area analysis. Restrictions can be found on the rest endpoint of the service.
        serviceAreaParams.restrictionAttributeNames = ["Non-routeable segments","Avoid passenger ferries","TurnRestriction","OneWay"]
        
        //Specify the travel direction.
        serviceAreaParams.travelDirection = .FromFacility
        
        //specifying the spatial reference output
        serviceAreaParams.outSpatialReference = self.mapView.spatialReference
        
        //specify the selected facility for the service area task.
        serviceAreaParams.setFacilitiesWithFeatures([self.selectedGraphic])
        
        //adding the barriers to the parameters
        var polygonBarriers = [AGSGraphic]()
        // get the barriers for the service area task
        for g in self.graphicsLayer.graphics as! [AGSGraphic] {
            if g.attributeAsStringForKey("barrierNumber") != nil {
                polygonBarriers.append(g)
            }
        }
        if polygonBarriers.count > 0 {
            serviceAreaParams.setPolygonBarriersWithFeatures(polygonBarriers)
        }
        
        //calls the solveServiceAreaWithParameters with modified params.
        self.saOp = self.saTask.solveServiceAreaWithParameters(serviceAreaParams)
    }
    
    //if error encountered while executing sa task's retrieveDefaultServiceAreaTaskParameters operation
    func serviceAreaTask(serviceAreaTask: AGSServiceAreaTask!, operation op: NSOperation!, didFailToRetrieveDefaultServiceAreaTaskParametersWithError error: NSError!) {
        
        //stop activity indicator
        SVProgressHUD.dismiss()
        
        //show error message
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - UIAlertViewDelegate Methods
    
    //if the operation was cancelled.
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        //cancel the sa operation
        self.saOp.cancel()
        self.saOp = nil
    }
    
    //MARK: - Action Methods
    
    
    @IBAction func findServiceArea() {
    
        //retrieves the default parameters for the service area task from the server
        //the saOp property will keep tract of the operationm in case we need to cancel it at any point.
        self.saOp = self.saTask.retrieveDefaultServiceAreaTaskParameters()
        
        //showing activity indicator
        SVProgressHUD.showWithStatus("Finding service area")
    
    }
    
    
    //performed when the user taps on the remove barrier button on the barrier callout.
    @IBAction func removeBarrierClicked() {
    
        //barrier count decreases
        self.numBarriers--
        
        //remove the selected graphic
        self.graphicsLayer.removeGraphic(self.selectedGraphic)
        
        
        //release the selected graphic
        self.selectedGraphic = nil
        
        //hide the callout
        self.mapView.callout.hidden = true
    }
    
    //if user clears everything on the map to start over.
    @IBAction func clearAll(sender: AnyObject) {
    
        //set barrier counter back to 0
        self.numBarriers = 0
        
        //remove all graphics
        self.graphicsLayer.removeAllGraphics()
        
        
        //reset activitySegControl to find service area mode
        self.activitySegControl.selectedSegmentIndex = 0
        
        //reset status message label
        self.statusMessageLabel.text = "Select the facility to find its service area"
        
        //nil out the sketch layer if it exists.
        if self.sketchLayer != nil {
            self.sketchLayer.clear()
        }
    
    }
    
    
    
    // clear the sketch layer
    @IBAction func clearSketchLayer(sender: AnyObject) {
        self.sketchLayer.clear()
    }
    
    //when the specific activity is selected.
    @IBAction func activitySegValueChanged(segCtrl:UISegmentedControl) {
    
        switch segCtrl.selectedSegmentIndex {
            //this case is when the mode is "Find Service Area"
        case 0:
            // update status message label
            self.statusMessageLabel.text = "Select the facility to find its service area"
            
            // if we have a sketch layer on the map, remove it
            if (self.mapView.mapLayers as! [AGSLayer]).contains(self.sketchLayer) {
                self.mapView.removeMapLayerWithName(self.sketchLayer.name)
                self.sketchLayer = nil
                //assiging the touch delegate to self instead of sketch layer
                self.mapView.touchDelegate = self
            }
            //this case is when the user wants to add barriers.
        case 1:
            // update status message label
            self.statusMessageLabel.text = "Sketch the barriers"
            
            //create the sketch layer with a Spatial Ref and add it to the map.
            let geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
            self.sketchLayer = AGSSketchGraphicsLayer(geometry: geometry)
            self.mapView.addMapLayer(self.sketchLayer, withName:"SketchLayer")
            
            //set the touch delegate to the sketch layer.
            self.mapView.touchDelegate = self.sketchLayer
        default:
            break
        }
    }
    
    
    //when the user presses the add button to add the sketched barrier to the graphics layer.
    @IBAction func addBarier(sender:AnyObject) {
    
        //grab the geometry, then clear the sketch
        let geometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        self.sketchLayer.clear()
        
        //Prepare symbol and attributes for the Stop/Barrier
        var attributes = [NSObject:AnyObject]()
        var symbol:AGSSymbol!
        
        //increament the barrier count
        self.numBarriers++
        
        //add the barrier count to the graphic attributes dictionary
        attributes["barrierNumber"] = self.numBarriers
        
        //you can set additional properties on the barrier here
        symbol = self.barrierSymbol()
        let g = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
        self.graphicsLayer.addGraphic(g)
    }
    
    //MARK: - Helper Methods
    
    func respondToGeomChanged(notifications: NSNotification) {
        //Enable/disable UI elements appropriately
        self.addBarrierButton.enabled = self.sketchLayer.geometry.isValid()
        self.clearSketchButton.enabled = !self.sketchLayer.geometry.isEmpty()
    }
    
    //MARK: Symbols
    
    //generates the symbol for the time break 1.
    func serviceAreaSymbolBreak1() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        //the outline symbol
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor(red: 0, green: 1, blue: 1, alpha: 0.5)
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        
        //the color of the fill.
        let sls2 = AGSSimpleFillSymbol()
        sls2.color = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
        sls2.style = .Solid
        cs.addSymbol(sls2)
        
        return cs
    }
    
    //generates the symbol for the time break 2.
    func serviceAreaSymbolBreak2() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        //the outline symbol
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor(red: 1, green: 1, blue: 0, alpha: 0.5)
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        
        //the color of the fill.
        let sls2 = AGSSimpleFillSymbol()
        sls2.color = UIColor(red: 1, green: 0, blue: 0, alpha: 0.25)
        sls2.style = .Solid
        cs.addSymbol(sls2)
        
        return cs
    }
    
    
    // default symbol for the barriers
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
    
    //MARK: - segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSettingsSegueIdentifier {
            let controller = segue.destinationViewController as! SettingsViewController
            controller.parameters = self.parameters
            
            //present as form sheet for iPad
            if  AGSDevice.currentDevice().isIPad() {
                controller.modalPresentationStyle = .FormSheet
            }
        }
    }
}
