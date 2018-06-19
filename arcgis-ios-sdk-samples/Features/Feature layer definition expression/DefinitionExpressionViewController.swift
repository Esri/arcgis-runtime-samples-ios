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

class DefinitionExpressionViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureLayer:AGSFeatureLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DefinitionExpressionViewController"]
        
        //initialize map using topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13630484, y: 4545415, spatialReference: AGSSpatialReference.webMercator()), scale: 90000)
        
        //assign map to the map view's map
        self.mapView.map = self.map
        
        //create feature table using a url to feature server's layer
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0")!)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the map
        self.map.operationalLayers.add(self.featureLayer)
        
    }
    
    @IBAction func applyDefinitionExpression() {
        //adding definition expression to show specific features only
        self.featureLayer.definitionExpression = "req_Type = 'Tree Maintenance or Damage'"
    }
    
    @IBAction func resetDefinitionExpression() {
        //reset definition expression
        self.featureLayer.definitionExpression = ""
    }
}
