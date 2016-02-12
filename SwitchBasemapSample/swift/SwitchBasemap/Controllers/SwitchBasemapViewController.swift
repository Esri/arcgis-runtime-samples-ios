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

class SwitchBasemapViewController: UIViewController, AGSWebMapDelegate, BasemapPickerDelegate {
    
    //map view object
    @IBOutlet weak var mapView: AGSMapView!
    //web map object
    var webMap:AGSWebMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupWebMap();
        
        //
//        let query = AGSQuery()
//        query.`where`
        print("something \(webMap)")
        //
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Private methods
    
    //load the default web map
    func setupWebMap() {
        self.webMap = AGSWebMap(itemId: kWebMapId, credential: nil);
        self.webMap.delegate = self;
    }
    
    //web map loaded successfully, open the web map into the map view
    func webMapDidLoad(webMap: AGSWebMap!) {
        print("Web map loaded!!");
        webMap.openIntoMapView(self.mapView)
    }
    
    //switch the basemap of the default web map with the selected base map
    func switchBasemapwithBasemap(basemap:AGSWebMapBaseMap) {
        self.webMap.switchBaseMapOnMapView(basemap)
    }
    
    //hide the list or grid view controller
    func dismissController() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: Basemap Picker delegate
    
    func basemapPickerController(controller: UIViewController, didSelectBasemap basemap: AGSWebMapBaseMap) {
        //switch the base map and hide the controller
        switchBasemapwithBasemap(basemap)
        dismissController()
    }
    
    func basemapPickerControllerDidCancel(controller: UIViewController)  {
        //hide the controller
        dismissController()
    }
    
    //MARK: Navigation
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)  {
        //assign delegate for the list and grid view controllers
        if segue.identifier == kSegueListView {
            (segue.destinationViewController as! BasemapsListViewController).delegate = self
        }
        else if segue.identifier == kSegueGridView {
            (segue.destinationViewController as! BasemapsGridViewController).delegate = self
        }
    }
}

