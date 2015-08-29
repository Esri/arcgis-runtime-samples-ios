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

import UIKit
import ArcGIS

class DisplayMapViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with a basemap
        let map = AGSMap(basemap: AGSBasemap.imageryBasemap())
        
        //assign the map to the map view
        self.mapView.map = map
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayMapViewController"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
