//
//  POIMapDetailViewController.swift
//  arcgis-ios-sdk-samples
//
//  Created by İkbal Yaşar on 6/29/17.
//  Copyright © 2017 Esri. All rights reserved.
//

import UIKit
import ArcGIS



class CustomCalloutPopUpViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var lblName: UILabel!
    private var map:AGSMap!
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create popup map view
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        //assign map to the map view
        self.mapView.map = self.map
      }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}
