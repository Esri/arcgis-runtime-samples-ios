//
// Copyright 2015 ESRI
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

class MainViewController: UIViewController, AGSMapViewLayerDelegate, TOCViewControllerDelegate {

    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var layersButton: UIBarButtonItem!
    
    var contentsTree:AGSMapContentsTree!
    var popOverController:UIPopoverController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the base map.
        let mapUrl = NSURL(string: "http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Base Map")
        self.mapView.layerDelegate = self;
        
        //add open street map.
        let osmLayer = AGSOpenStreetMapLayer()
        self.mapView.addMapLayer(osmLayer, withName:"Open Street Map")
        
        //add the bing map. Please use your own key. Here are the instructions: http://help.arcgis.com/en/arcgismobile/10.0/apis/iOS/2.1/concepts/index.html#/Bing_Maps_Layer/00pw0000004p000000/
        
//        let bmLayer = AGSBingMapLayer(appID: "<---Your Key Here--->", style: .Road)
//        self.mapView.addMapLayer(bmLayer, withName: "Bing Maps")
        
        let mapUrl3 = NSURL(string: "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer")
        let dynamicLyr3 = AGSDynamicMapServiceLayer(URL: mapUrl3)
        self.mapView.addMapLayer(dynamicLyr3, withName:"Census")
        
        //add a tiled layer
        let mapUrl5 = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer")
        let tiledLyr5 = AGSTiledMapServiceLayer(URL: mapUrl5)
        self.mapView.addMapLayer(tiledLyr5, withName:"Soil Survey")
        
        //add a feature layer.
        let featureLayer = AGSFeatureLayer(URL: NSURL(string: "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/0"), mode:.OnDemand)
        self.mapView.addMapLayer(featureLayer, withName:"Incidents")
        
        //Zooming to an initial envelope with the specified spatial reference of the map.
        let sr = AGSSpatialReference.webMercatorSpatialReference()
        let env = AGSEnvelope(xmin: -13639984,
            ymin:4537387,
            xmax:-13606734,
            ymax:4558866,
            spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        self.mapView.layerDelegate = self
        
        //disable the right bar button item until the map view is loaded
        self.navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        self.contentsTree = AGSMapContentsTree(mapView: self.mapView)

        //enable the right bar button item
        self.navigationItem.rightBarButtonItem?.enabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - TOCViewController delegate
    
    func dismissTOCViewController(controller: TOCViewController) {
        //in case of iPad dismiss the pop over controller
        if AGSDevice.currentDevice().isIPad() {
            self.popOverController.dismissPopoverAnimated(true)
        }
        else {    //in case of iphone dismiss the modal view controller
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func contentButtonAction() {
        //using the TOCStoryboard instantiate the TOCViewController
        let storyboard = UIStoryboard(name: "TOCStoryboard", bundle: nil)
        let tOCViewController = storyboard.instantiateInitialViewController() as! TOCViewController
        //pass the sublayers on the root layer info to the TOCViewController
        tOCViewController.itemsArray = self.contentsTree.root.subLayers
        //set the delegate
        tOCViewController.delegate = self
        //present the view as popOver if current device is iPad
        //else present modally
        if AGSDevice.currentDevice().isIPad() {
            tOCViewController.preferredContentSize = CGSize(width: 300, height: 500)
            self.popOverController = UIPopoverController(contentViewController: tOCViewController)
//            self.popOverController.setPopoverContentSize(CGSizeMake(200, 500), animated: true)
            self.popOverController.presentPopoverFromBarButtonItem(self.layersButton, permittedArrowDirections: .Any, animated: true)
        }
        else {
            self.presentViewController(tOCViewController, animated: true, completion: nil)
        }
    }

}
