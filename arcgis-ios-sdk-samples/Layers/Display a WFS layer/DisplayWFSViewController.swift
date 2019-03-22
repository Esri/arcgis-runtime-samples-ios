// Copyright 2019 Esri.
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

class DisplayWFSViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    private var wfsFeatureTable: AGSWFSFeatureTable!
    private var lastQuery: AGSCancelable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize a map with topographic basemap
        let map = AGSMap(basemap: .topographic())
        
        // A URL to the GetCapabilities endpoint of a WFS service
        let wfsServiceURL = URL(string: "https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer?service=wfs&request=getcapabilities")!
        
        // Name of the table to load
        let wfsTableName = "Seattle_Downtown_Features:Buildings"
        
        // Initialize a WFS feature table with service URL and uniquely identifying table name
        wfsFeatureTable = AGSWFSFeatureTable(url: wfsServiceURL, tableName: wfsTableName)
        
        // Set feature request mode to manual - only manual is supported at v100.5.
        // In this mode, you must manually populate the table - panning and zooming won't request features automatically.
        wfsFeatureTable.featureRequestMode = .manualCache
    
        // Initialize a feature layer from WFS feature table
        let wfsFeatureLayer = AGSFeatureLayer(featureTable: self.wfsFeatureTable)
        
        // Create a simple renderer
        let simpleLineSymbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 3.0)
        let renderer = AGSSimpleRenderer(symbol: simpleLineSymbol)
        
        // Apply renderer to feature layer
        wfsFeatureLayer.renderer = renderer
        
        // Add feature layer to the map
        map.operationalLayers.add(wfsFeatureLayer)
        
        // Query for features whenever map's viewpoint changes
        self.mapView.viewpointChangedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.populateFeaturesFromQuery()
            }
        }
        
        // Set initial viewpoint
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -122.341581, yMin: 47.613758, xMax: -122.332662, yMax: 47.617207, spatialReference: .wgs84()))
        
        // Assign the map to the map view
        mapView.map = map

        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayWFSViewController"]
    }
    
    private func populateFeaturesFromQuery() {
        // If there is an existing query request, cancel it
        if let lastQuery = self.lastQuery {
            lastQuery.cancel()
        }
        // Create query parameters
        let params = AGSQueryParameters()
        params.geometry = self.mapView.visibleArea?.extent
        params.spatialRelationship = .intersects
        
        // Show progress
        SVProgressHUD.show(withStatus: "Querying")
    
        // Populate features based on query
        self.lastQuery = self.wfsFeatureTable.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
            // Check and get results
            if let result = result {
                // The resulting features should be displayed on the map
                // Print the count of features
                print("Populated \(result.featureEnumerator().allObjects.count) features.")
            }
            // Check for error. If it's a user canceled error, do nothing.
            // Otherwise, display an alert.
            else if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self?.presentAlert(error: error)
                } else {
                    return
                }
            }
            // Hide Progress
            SVProgressHUD.dismiss()
        }
    }
}
