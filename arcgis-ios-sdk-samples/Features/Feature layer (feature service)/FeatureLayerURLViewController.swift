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

class FeatureLayerURLViewController: UIViewController {

    @IBOutlet private weak var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerURLViewController"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.terrainWithLabels())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: AGSSpatialReference.webMercator()), scale: 300000)
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)

        //create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the operational layers
        map.operationalLayers.add(featureLayer)
    }

}
