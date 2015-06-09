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

let kDynamicMapServiceURL = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer"

let kResultsViewControllerIdentifier = "ResultsViewController"
let kResultsSegueIdentifier = "ResultsSegue"

class IdentifyTaskViewController: UIViewController, AGSMapViewTouchDelegate, AGSCalloutDelegate, AGSIdentifyTaskDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var graphicsLayer:AGSGraphicsLayer!
    var identifyTask:AGSIdentifyTask!
    var identifyParams:AGSIdentifyParameters!
    var mappoint:AGSPoint!
    var selectedGraphic:AGSGraphic!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.touchDelegate = self
        self.mapView.callout.delegate = self
        
        // create a dynamic map service layer
        let dynamicLayer = AGSDynamicMapServiceLayer(URL: NSURL(string: kDynamicMapServiceURL))
        
        // set the visible layers on the layer
        dynamicLayer.visibleLayers = [5]
        
        // add the layer to the map
        self.mapView.addMapLayer(dynamicLayer, withName:"Dynamic Layer")
        
        // since we alloc-init the layer, we must release it
        
        // create and add the graphics layer to the map
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        //create identify task
        self.identifyTask = AGSIdentifyTask(URL: NSURL(string: kDynamicMapServiceURL))
        self.identifyTask.delegate = self
        
        //create identify parameters
        self.identifyParams = AGSIdentifyParameters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSMapViewTouchDelegate methods
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        //store for later use
        self.mappoint = mappoint
        
        //the layer we want is layer ‘5’ (from the map service doc)
        self.identifyParams.layerIds = [5]
        self.identifyParams.tolerance = 3
        self.identifyParams.geometry = self.mappoint
        self.identifyParams.size = self.mapView.bounds.size
        self.identifyParams.mapEnvelope = self.mapView.visibleArea().envelope
        self.identifyParams.returnGeometry = true
        self.identifyParams.layerOption = .All
        self.identifyParams.spatialReference = self.mapView.spatialReference
        
        //execute the task
        self.identifyTask.executeWithParameters(self.identifyParams)
    
    }
    
    //MARK: - AGSCalloutDelegate methods
    
    //show the attributes if accessory button is clicked
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        
        //save the selected graphic, to later assign to the results view controller
        self.selectedGraphic = callout.representedObject as! AGSGraphic
        
        self.performSegueWithIdentifier(kResultsSegueIdentifier, sender:self)
    }
    
    
    //MARK: - AGSIdentifyTaskDelegate methods
    
    //results are returned
    func identifyTask(identifyTask: AGSIdentifyTask!, operation op: NSOperation!, didExecuteWithIdentifyResults results: [AnyObject]!) {
        
        //clear previous results
        self.graphicsLayer.removeAllGraphics()
        
        if results != nil && results.count > 0 {
            
            //add new results
            let symbol = AGSSimpleFillSymbol()
            symbol.color = UIColor(red: 0, green:0, blue:1, alpha:0.5)
            
            // for each result, set the symbol and add it to the graphics layer
            for result in results as! [AGSIdentifyResult] {
                result.feature.symbol = symbol
                self.graphicsLayer.addGraphic(result.feature)
            }
            
            //set the callout content for the first result
            //get the state name
            let stateName = (results[0] as! AGSIdentifyResult).feature.attributeAsStringForKey("STATE_NAME")
            self.mapView.callout.title = stateName
            self.mapView.callout.detail = "Click for more detail.."
            
            //show callout
            self.mapView.callout.showCalloutAtPoint(self.mappoint, forFeature:(results[0] as! AGSIdentifyResult).feature, layer:(results[0] as! AGSIdentifyResult).feature.layer, animated:true)
        }
    }
    
    
    //if there's an error with the query display it to the user
    func identifyTask(identifyTask: AGSIdentifyTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kResultsSegueIdentifier {
            let controller = segue.destinationViewController as! ResultsViewController
            //set our attributes/results into the results VC
            controller.results = self.selectedGraphic.allAttributes()
        }
    }
}
