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

let kDefaultMap = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Shaded_Relief/MapServer"
let kGPTask = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Elevation/ESRI_Elevation_World/GPServer/Viewshed"

class SynchronousGPViewController: UIViewController, AGSMapViewTouchDelegate, AGSMapViewLayerDelegate, AGSGeoprocessorDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var graphicsView:UIView!
    var graphicsLayer:AGSGraphicsLayer!
    var gpTask:AGSGeoprocessor!
    var gpOp:NSOperation!
    
    @IBOutlet weak var vsDistanceSlider:UISlider!
    @IBOutlet weak var vsDistanceLabel:UIBarButtonItem!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Adding the basemap.
        let mapUrl = NSURL(string: kDefaultMap)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Zooming to an initial envelope with the specified spatial reference of the map.
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -13639984, ymin:4537387, xmax:-13606734, ymax:4558866, spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        //important step in detecting the touch events on the map
        self.mapView.touchDelegate = self
        
        //step to call the mapViewDidLoad method to do the initiation of GP.
        self.mapView.layerDelegate = self
        
        //add  graphics layer for showing results of the viewshed calculation
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Viewshed")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewLayerDelegate
    func mapViewDidLoad(mapView: AGSMapView!) {
        //set up the GP task
        self.gpTask = AGSGeoprocessor(URL: NSURL(string: kGPTask))
        self.gpTask.delegate = self //required to respond to the gp response.
        self.gpTask.processSpatialReference = self.mapView.spatialReference
        self.gpTask.outputSpatialReference = self.mapView.spatialReference
    }
    
    
    //MARK: - AGSMapViewTouchDelegate
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        //clearing the graphic layer before any update.
        self.graphicsLayer.removeAllGraphics()
        
        //adding a simple marker to the view point on the map.
        let myMarkerSymbol = AGSSimpleMarkerSymbol(color: UIColor(red: 0, green: 1, blue: 0, alpha: 0.25))
        myMarkerSymbol.size = CGSizeMake(10,10)
        myMarkerSymbol.outline = AGSSimpleLineSymbol(color: UIColor.redColor(), width:1)
        
        //create a graphic
        let agsGraphic = AGSGraphic(geometry: mappoint, symbol: myMarkerSymbol, attributes: nil)
        
        //add graphic to graphics layer
        self.graphicsLayer.addGraphic(agsGraphic)
        
        //creating a feature set for the input pareameter for the GP.
        let featureSet = AGSFeatureSet()
        featureSet.features = [agsGraphic]
        
        //create input parameter
        let paramloc = AGSGPParameterValue(name: "Input_Observation_Point", type: .FeatureRecordSetLayer, value:featureSet)
        
        //creating the linear unit distance parameter for the GP.
        let vsDistance = AGSGPLinearUnit()
        vsDistance.distance = Double(self.vsDistanceSlider.value)
        vsDistance.units = .Miles
        
        //create input parameter
        let paramdt = AGSGPParameterValue(name: "Viewshed_Distance", type:.LinearUnit, value:vsDistance)
        
        //add parameters to param array
        let params = [paramloc, paramdt]
        
        //execute the GP task with parameters - synchrounously.
        self.gpOp = self.gpTask.executeWithParameters(params) // keep track of the gp operation so that we can cancel it if user wants.
        
        //showing activity indicator
        SVProgressHUD.showWithStatus("Loading Viewshed...")
        
    }
    
    
    //MARK: - GeoprocessorDelegate
    
    //this is the delegate method that getscalled when gp task completes successfully.
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, didExecuteWithResults results: [AnyObject]!, messages: [AnyObject]!) {
        
        if results != nil && results.count > 0 {
            
            //get the first result
            let result = results[0] as! AGSGPParameterValue
            let fs = result.value as! AGSFeatureSet
            
            //loop through all graphics in feature set and add them to map
            for graphic in fs.features as! [AGSGraphic] {
                
                //create and set a symbol to graphic
                let fillSymbol = AGSSimpleFillSymbol()
                fillSymbol.color = UIColor.purpleColor().colorWithAlphaComponent(0.25)
                graphic.symbol = fillSymbol
                
                //add graphic to graphics layer
                self.graphicsLayer.addGraphic(graphic)
            }
            
            //stop activity indicator
            SVProgressHUD.dismiss()
            
            //zoom to graphics layer extent
            let env = self.graphicsLayer.fullEnvelope.mutableCopy() as! AGSMutableEnvelope
            env.expandByFactor(1.2)
            self.mapView.zoomToEnvelope(env, animated:true)
        }
        
    }
    
    //if there's an error with the gp task give info to user
    func geoprocessor(geoprocessor: AGSGeoprocessor!, operation op: NSOperation!, didFailExecuteWithError error: NSError!) {
        
        //stop activity indicator
        SVProgressHUD.dismiss()
        
        //show error message
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - Action Methods
    
    @IBAction func vsDistanceSliderChanged(sender:AnyObject) {
        //show current distance
        self.vsDistanceLabel.title = String(format: "%.1f miles", self.vsDistanceSlider.value)
    }
    
    //MARK: - UIAlertViewDelegate Methods
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        //cancel the operation
        self.gpOp.cancel()
        self.gpOp = nil
        
        //clear the graphics layer.
        self.graphicsLayer.removeAllGraphics()
    }
}
