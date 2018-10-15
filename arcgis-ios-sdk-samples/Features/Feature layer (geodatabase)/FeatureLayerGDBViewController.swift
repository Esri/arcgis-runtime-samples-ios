// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class FeatureLayerGDBViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var geodatabase:AGSGeodatabase!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerGDBViewController"]
        
        //instantiate map with basemap
        let map = AGSMap(basemap: .imageryWithLabels())
        
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13214155, y: 4040194, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 35e4)
        
        //instantiate geodatabase with name
        self.geodatabase = AGSGeodatabase(name: "LA_Trails")
        
        //load the geodatabase for feature tables
        self.geodatabase.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                let featureTable = self!.geodatabase.geodatabaseFeatureTable(withName: "Trailheads")!
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                self?.mapView.map?.operationalLayers.add(featureLayer)
            }
        }
        
        //assign map to the map view
        self.mapView.map = map
    }

}
