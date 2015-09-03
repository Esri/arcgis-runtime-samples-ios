//
//  FeatureLayerURLViewController.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 8/28/15.
//  Copyright (c) 2015 Esri. All rights reserved.
//

import UIKit
import ArcGIS

class FeatureLayerURLViewController: UIViewController {

    @IBOutlet private weak var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerURLViewController"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.terrainWithLabelsBasemap())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: AGSSpatialReference.webMercator()), scale: 300000)
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9"))

        //create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the operational layers
        map.operationalLayers.addObject(featureLayer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
