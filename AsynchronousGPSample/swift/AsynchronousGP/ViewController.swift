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

import Foundation
import ArcGIS

let kDefaultMap = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
let kGPTask = "http://sampleserver2.arcgisonline.com/ArcGIS/rest/services/PublicSafety/EMModels/GPServer/ERGByChemical"
let kSegueSettingsView = "SegueSettingsView"

class ViewController:UIViewController, AGSMapViewTouchDelegate, AGSGeoprocessorDelegate, AGSMapViewLayerDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var wdDegreeLabel: UILabel!
    @IBOutlet weak var statusMsgLabel: UILabel!
    @IBOutlet weak var wdDegreeSlider: UISlider!
    
    var graphicsLayer:AGSGraphicsLayer!
    var gpTask:AGSGeoprocessor!
    var parameters = AsyncGPParameters()
    
    override func viewDidLoad() {
        //Add teh basemap
        let mapUrl = NSURL(string: kDefaultMap)
        let tiledLayer = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLayer)
        
        //Zooming to an intial envelope with the specified spatial reference of the map
        let spatialReference = AGSSpatialReference(WKID: 102100)
        let envelope = AGSEnvelope(xmin: -13639984, ymin: 4537387, xmax: -13606734, ymax: 4558866, spatialReference: spatialReference)
        self.mapView.zoomToEnvelope(envelope, animated: true)
        
        //important step in detecting the touch events on the map
        self.mapView.touchDelegate = self
        
        //step to call the mapViewDidLoad method to do the initiation of GP
        self.mapView.layerDelegate = self
        
        //add graphics layer for showing results of the chemical spill analysis
        self.graphicsLayer = AGSGraphicsLayer.graphicsLayer() as? AGSGraphicsLayer
        
        self.mapView.addMapLayer(self.graphicsLayer, withName: "ChemicalERG")
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.dismissHUD()
    }
    
    //MARK: AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        //set up the gp task
        self.gpTask = AGSGeoprocessor(URL: NSURL(string: kGPTask))
        self.gpTask.delegate = self
        self.gpTask.processSpatialReference = self.mapView.spatialReference
        self.gpTask.outputSpatialReference = self.mapView.spatialReference
    }
    
    //MARK: AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        //clear graphic layer before any update
        self.graphicsLayer?.removeAllGraphics()
        
        //create a symbol to show user tap location on map
        let myMarkerSymbol = AGSSimpleMarkerSymbol.simpleMarkerSymbolWithColor(UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.25)) as! AGSSimpleMarkerSymbol
        myMarkerSymbol.size = CGSizeMake(10, 10)
        myMarkerSymbol.outline = AGSSimpleLineSymbol(color: UIColor.redColor(), width: 1)
        
        //create a graphic
        let graphic = AGSGraphic(geometry: mappoint, symbol: myMarkerSymbol, attributes: nil)
        
        //add graphic to graphics layer
        self.graphicsLayer.addGraphic(graphic)
        
        //create a feature set for the input parameter
        let featureSet = AGSFeatureSet()
        featureSet.features = [graphic]

        //assign the new feature set and wind direction values to the parameter object
        self.parameters.featureSet = featureSet
        self.parameters.windDirection = NSDecimalNumber(float: self.wdDegreeSlider.value)
        
        //get the parameters array from the parameters object
        let parametersArray = self.parameters.parametersArray()
        
        //submit the gp job
        //the interval property of the gptask is not set to a value explicitly, default is 5 sec
        if let newTask = self.gpTask {
            newTask.submitJobWithParameters(parametersArray)
            self.showHUDWithStatus("Loading")
        }
    }
    
    //MARK: GeoprocessorDelegate
    
    //this is the delegate method that gets called when job submits successfully
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, didSubmitJob jobInfo: AGSGPJobInfo!) {
        //update the status
        self.statusMsgLabel.text = "Geoprocessing Job Submitted!"
    }
    
    //this is the delegate method that gets called when geoprocessing task completes successfully
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, jobDidSucceed jobInfo: AGSGPJobInfo!) {
        //job succeeded, query result data
        geoprocessor.queryResultData(jobInfo.jobId, paramName: "outerg_shp")
    }
    
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, didQueryWithResult result: AGSGPParameterValue!, forJob jobId: String!) {
        //get the result
        let featureSet = result.value as! AGSFeatureSet
        //loop through all the graphics in feature set and add them to the map
        for graphic in featureSet.features {
            //create and set a symbol to graphic
            let fillSymbol = AGSSimpleFillSymbol.simpleFillSymbol() as! AGSSimpleFillSymbol
            fillSymbol.color = UIColor.purpleColor().colorWithAlphaComponent(0.25)
            (graphic as! AGSGraphic).symbol = fillSymbol
            
            //add graphic to graphics layer
            self.graphicsLayer.addGraphic(graphic as! AGSGraphic)
        }
        
        //zoom to the graphic layer extent
        let envelope = self.graphicsLayer.fullEnvelope.mutableCopy() as! AGSMutableEnvelope
        envelope.expandByFactor(1.2)
        self.mapView.zoomToEnvelope(envelope, animated: true)
        
        //showing status
        self.statusMsgLabel.text = "Job Succeeded with Results!"
        
        //update status
        //        self.performSelector(@selector(changeStatusLabel:), withObject:"Tap on the map to get the spill analysis", afterDelay:4)
        dispatch_after(4, dispatch_get_main_queue(), {
            self.statusMsgLabel.text = "Tap on the map to get the spill analysis"
        })
        
        self.dismissHUD()
    }
    
    //if error encountered while executing gp task
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, ofType opType: AGSGPAsyncOperationType, didFailWithError error: NSError!, forJob jobId: String!) {
        self.dismissHUD()
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    //if there is an error with the gp task give info to user
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, jobDidFail jobInfo: AGSGPJobInfo!) {
        self.dismissHUD()
        for message in jobInfo.messages {
            print("\((message as! AGSGPMessage).description)")
        }
        
        //Update status
        self.statusMsgLabel.text = "Job Failed"
        
        //reset the status
        dispatch_after(4, dispatch_get_main_queue(), {
            self.statusMsgLabel.text = "Tap on the map to get the spill analysis"
        })
    }
    
    //MARK: Action Methods
    
    @IBAction func degreeSlideChanged(sender: UISlider) {
        //show direction angle
        self.wdDegreeLabel.text = "\(Int(self.wdDegreeSlider.value)) degrees"
    }
    
    
    func changeStatusLabel(message:String) {
        self.statusMsgLabel.text = message
    }
    
    //MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == kSegueSettingsView {
            (segue.destinationViewController as! AsyncGPSettingsViewController).parameters = self.parameters
        }
    }
    
    //MARK: Activity indicator methods
    
    func showHUDWithStatus(status:String) {
        SVProgressHUD.showWithStatus(status)
        self.mapView.userInteractionEnabled = false
    }
    
    func dismissHUD() {
        SVProgressHUD.dismiss()
        self.mapView.userInteractionEnabled = true
    }
}
