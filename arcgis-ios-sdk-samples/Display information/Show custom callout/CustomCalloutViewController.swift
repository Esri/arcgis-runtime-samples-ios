//
//  CustomCalloutViewController.swift
//  arcgis-ios-sdk-samples
//
//  Created by İkbal Yaşar on 6/15/17.
//  Copyright © 2017 Esri. All rights reserved.
//

import UIKit
import ArcGIS

class CustomCalloutViewController: UIViewController , AGSGeoViewTouchDelegate  {
    
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    var customCalloutPopUpViewController : CustomCalloutPopUpViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CustomCalloutViewController","CustomCalloutPopUpViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //assign map to the map view
        self.mapView.map = self.map
        //register as the map view's touch delegate
        //in order to get tap notifications
        self.mapView.touchDelegate = self
        //zoom to custom view point
        self.mapView.setViewpointCenter(AGSPoint(x: -1.2e7, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 4e7, completion: nil)
        
        
        // create custom callout controller
        let frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        self.customCalloutPopUpViewController = createViewController("CustomCallout", controllerIdentifier: "CustomCalloutPopUpViewController") as! CustomCalloutPopUpViewController;
        self.customCalloutPopUpViewController.view.frame = frame;
        self.customCalloutPopUpViewController.view.clipsToBounds = true;
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //user tapped on the map
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //if the callout is not shown, show the callout with the coordinates of the tapped location
        if self.mapView.callout.isHidden {
            
             // create custom callout attributes
            self.mapView.callout.customView = self.customCalloutPopUpViewController.view
            self.customCalloutPopUpViewController.lblName.text =  String(format: "x: %.2f, y: %.2f", mapPoint.x, mapPoint.y)
            // popup map view set zoom scale
            self.customCalloutPopUpViewController.mapView.setViewpointCenter(AGSPoint(x: mapPoint.x, y: mapPoint.y, spatialReference: AGSSpatialReference.webMercator()), scale: 30000, completion: nil)
            self.mapView.callout.isAccessoryButtonHidden = true
            self.mapView.callout.show(at: mapPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
        }
        else {  //hide the callout
            self.mapView.callout.dismiss()
        }
    }
    
    // createViewController class. Use viewDidload
    func createViewController(_ storyboard: String, controllerIdentifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: controllerIdentifier);
        return vc;
    }
}


