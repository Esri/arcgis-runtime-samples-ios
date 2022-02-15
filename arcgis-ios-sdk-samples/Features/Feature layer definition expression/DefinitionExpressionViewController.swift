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
    @IBOutlet private weak var mapView: AGSMapView! {
        mapView.map = makeMap()
    }
    
    static let featureServiceURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0")
    let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url: featureServiceURL!))
    var manualDisplayFilterDefinition: AGSManualDisplayFilterDefinition?
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        let viewpoint = AGSViewpoint(latitude: -122.44014487516885, longitude: 37.772296660953138, scale: 100_000)
        map.initialViewpoint = viewpoint
        map.operationalLayers.add(featureLayer)
        map.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                guard let damagedTrees = AGSDisplayFilter(name: "Damaged Trees", whereClause: "req_type LIKE '%Tree Maintenance%'") else { return }
                self.manualDisplayFilterDefinition = AGSManualDisplayFilterDefinition(activeFilter: damagedTrees, availableFilters: [damagedTrees])
            }
        }
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DefinitionExpressionViewController"]
        
        // initialize map using topographic basemap
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        // assign map to the map view's map
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13630484, y: 4545415, spatialReference: .webMercator()), scale: 90000))
        
        // create feature table using a url to feature server's layer
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0")!)
        // create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        // add the feature layer to the map
        map.operationalLayers.add(featureLayer)
        
    }
    
    @IBAction func applyDefinitionExpression() {
        // adding definition expression to show specific features only
        self.featureLayer.definitionExpression = "req_Type = 'Tree Maintenance or Damage'"
    }
    
    @IBAction func resetDefinitionExpression() {
        // reset definition expression
        self.featureLayer.definitionExpression = ""
    }
}
