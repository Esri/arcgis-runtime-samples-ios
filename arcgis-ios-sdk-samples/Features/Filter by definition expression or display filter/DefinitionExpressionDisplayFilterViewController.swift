// Copyright 2022 Esri.
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

class DefinitionExpressionDisplayFilterViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Assign the map to the map view's map.
            mapView.map = makeMap()
        }
    }
    
    /// The URL to the feature service, tracking incidents in San Francisco.
    static let featureServiceURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0")!
    /// The feature layer made with the feature service URL.
    let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url: featureServiceURL))
    /// The display filter definition to apply to the feature layer.
    var displayFilterDefinition: AGSDisplayFilterDefinition?
    /// The definition expression to apply to the feature layer.
    var definitionExpression: String = ""
    
    /// Applies the definition expression.
    @IBAction func applyDefinitionExpression() {
        // Set the definition expression.
        displayFilterDefinition = nil
        definitionExpression = "req_Type = 'Tree Maintenance or Damage'"
        showFeatureCount()
    }
    
    /// Applies the display filter
    @IBAction func applyFilter() {
        definitionExpression = ""
        // Create a display filter with a name and an SQL expression.
        guard let damagedTrees = AGSDisplayFilter(name: "Damaged Trees", whereClause: "req_type LIKE '%Tree Maintenance%'") else { return }
        // Set the manual display filter definition using the display filter.
        let manualDisplayFilterDefinition = AGSManualDisplayFilterDefinition(activeFilter: damagedTrees, availableFilters: [damagedTrees])
        // Apply the display filter definition.
        displayFilterDefinition = manualDisplayFilterDefinition
        showFeatureCount()
    }
    
    /// Reset the definition expression.
    @IBAction func resetDefinitionExpression() {
        definitionExpression = ""
        displayFilterDefinition = nil
        showFeatureCount()
    }
    
    /// Create a map and set its attributes.
    func makeMap() -> AGSMap {
        // Initialize the map with the topographic basemap style.
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        // Set the initial viewpoint.
        let viewpoint = AGSViewpoint(latitude: 37.772296660953138, longitude: -122.44014487516885, scale: 100_000)
        map.initialViewpoint = viewpoint
        // Add the feature layer to the map's operational layers.
        map.operationalLayers.add(featureLayer)
        return map
    }
    
    /// Count the features according to the applied expressions.
    func showFeatureCount() {
        // Set the extent to the current view.
        let extent = mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry.extent
        // Create the query parameters and set its geometry.
        let queryParameters = AGSQueryParameters()
        queryParameters.geometry = extent
        // Apply the expressions to the feature layer.
        featureLayer.displayFilterDefinition = displayFilterDefinition
        featureLayer.definitionExpression = definitionExpression
        // Query the feature count using the parameters.
        featureLayer.featureTable?.queryFeatureCount(with: queryParameters) { [weak self] count, error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Present the current feature count.
                self.presentAlert(title: "Current feature count", message: "\(count) features")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DefinitionExpressionDisplayFilterViewController"]
    }
}
