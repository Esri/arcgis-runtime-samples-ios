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
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Assign the map to the map view's map.
            mapView.map = makeMap()
        }
    }
    
    static let featureServiceURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0")
    let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url: featureServiceURL!))
    var manualDisplayFilterDefinition: AGSManualDisplayFilterDefinition?
    var displayFilterDefinition: AGSDisplayFilterDefinition?
    var definitionExpression: String?
    
    @IBAction func applyDefinitionExpression() {
        // adding definition expression to show specific features only
        displayFilterDefinition = nil
        definitionExpression = "req_Type = 'Tree Maintenance or Damage'"
        countFeatures()
    }
    
    @IBAction func applyFilter() {
        definitionExpression = ""
        displayFilterDefinition = manualDisplayFilterDefinition
        countFeatures()
        // expression should cut trees and filter should have a different count after trees are reduced
        // update buttons (apply definition expression, apply display filter)
    }
    
    @IBAction func resetDefinitionExpression() {
        // reset definition expression
        definitionExpression = ""
        displayFilterDefinition = nil
        countFeatures()
    }
    
    func makeMap() -> AGSMap {
        // Initialize the map with the topographic basemap style.
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        // Set the initial viewpoint.
        let viewpoint = AGSViewpoint(latitude: 37.772296660953138, longitude: -122.44014487516885, scale: 100000)
        map.initialViewpoint = viewpoint
        // Add the feature layer to the map's operational layers.
        map.operationalLayers.add(featureLayer)
        // Load the map.
        map.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Create a display filter with a name and an SQL expression.
                guard let damagedTrees = AGSDisplayFilter(name: "Damaged Trees", whereClause: "req_type LIKE '%Tree Maintenance%'") else { return }
                // Set the manual display filter definition using the display filter.
                self.manualDisplayFilterDefinition = AGSManualDisplayFilterDefinition(activeFilter: damagedTrees, availableFilters: [damagedTrees])
            }
        }
        return map
    }
    
    func countFeatures() {
        let extent = mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry.extent
        
        let queryParameters = AGSQueryParameters()
        queryParameters.geometry = extent
        
        featureLayer.featureTable?.queryFeatureCount(with: queryParameters) { [weak self] count, error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.presentAlert(title: "Current feature count", message: "\(count) features")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DefinitionExpressionViewController"]
    }
}
