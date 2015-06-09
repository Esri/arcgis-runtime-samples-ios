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

import UIKit
import ArcGIS

let FEATURE_SERVICE_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/2"
let BASEMAP_URL = "http://services.arcgisonline.com/arcgis/rest/services/World_Topo_Map/MapServer"

let NONE_FIELD_VALUE = "None"

class MainViewController: UIViewController, AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSLayerDelegate, LegendViewControllerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var legendContainerView:UIView!
    
    var featureLayer:AGSFeatureLayer!
    var legendViewController:LegendViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //hide the legend view until the dynamic layer loads
        self.legendContainerView.hidden = true;
        
        //assign self as the map view delegates
        self.mapView.layerDelegate = self
        self.mapView.callout.delegate = self
        
        //zoom into the California
        let envelope = AGSEnvelope(xmin: -14029650.509177, ymin: 3560436.632155, xmax: -12627306.217347, ymax: 5430229.021262, spatialReference:AGSSpatialReference.webMercatorSpatialReference())
        self.mapView.zoomToEnvelope(envelope, animated:false)
        
        //loading World_Topo_Map as basemap
        let tiledLayer = AGSTiledMapServiceLayer(URL: NSURL(string: BASEMAP_URL))
        self.mapView.addMapLayer(tiledLayer)
        
        //initialize the feature layer and assign the delegate
        self.featureLayer = AGSFeatureLayer(URL: NSURL(string: FEATURE_SERVICE_URL), mode: .Snapshot)
        self.featureLayer.delegate = self
        //using definition expression to get counties(features) for just California
        self.featureLayer.definitionExpression = "state_name = 'California'"
        self.featureLayer.outFields = ["*"]
        self.mapView.addMapLayer(self.featureLayer)
        
        //notification for features did load for a feature layer
        //will hide the progress hud once the features load
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dismissProgressHUD", name: AGSFeatureLayerDidLoadFeaturesNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //show progress hud until the features load
        SVProgressHUD.showWithStatus("Loading Features")
    }
    
    func dismissProgressHUD() {
        //dismiss the progress hud
        SVProgressHUD.dismiss()
        //un hide the legend view controller
        self.legendContainerView.hidden = false
    }
    
    //MARK: - AGSLayerDelegate methods
    
    func layerDidLoad(layer: AGSLayer!) {
        //once the feature layer gets loaded
        //assign the layer's fields to the legend view controller
        self.legendViewController.classificationFields = self.featureLayer.fields as! [AGSField]
    }
    
    func layer(layer: AGSLayer!, didFailToLoadWithError error: NSError!) {
        //display the error to the user via alertview
        UIAlertView(title: "Error", message:error.localizedDescription, delegate:nil, cancelButtonTitle:"Ok").show()
    }
    
    //MARK: - AGSCalloutDelegate methods
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        //use the current selected classification field as title
        //and its value as the detail text
        if self.legendViewController != nil {
            let fieldName = self.legendViewController.selectedFieldName()
            let fieldValue = feature.attributeAsStringForKey(fieldName)
            callout.title = fieldName
            callout.detail = fieldValue
            return true
        }
        return false
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LegendEmbedSegue" {
            self.legendViewController = segue.destinationViewController as! LegendViewController
            //assign self as the delegate for legendViewController
            self.legendViewController.delegate = self
        }
    }
    
    //MARK: - LegendViewController delegate
    
    func legendViewController(legendViewController: LegendViewController, didGenerateRenderer renderer: AGSRenderer) {
        //assign the new renderer to the feature layer
        self.featureLayer.renderer = renderer
    }
    
    func legendViewController(legendViewController: LegendViewController, failedToGenerateRendererWithError error: NSError) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }

}
