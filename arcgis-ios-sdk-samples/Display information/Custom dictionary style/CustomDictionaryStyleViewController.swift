// Copyright 2020 Esri
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

class CustomDictionaryStyleViewController: UIViewController {
    /// Create the restaurants feature table from the feature service.
    let restaurantFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Redlands_Restaurants/FeatureServer/0")!)
    
    /// Load style symbol dictionary from shared resources.
    let styleURL = Bundle.main.url(forResource: "Restaurant", withExtension: "stylx")!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Display symbology using a geodatabase.
            displayFeatureLayer()
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsVector())
        return map
    }
    
    func displayFeatureLayer() {
        let featureLayer = AGSFeatureLayer(featureTable: restaurantFeatureTable)
        // Display features from the layer using Restaurant style symbols.
        featureLayer.renderer = AGSDictionaryRenderer(dictionarySymbolStyle: AGSDictionarySymbolStyle(url: styleURL))
        featureLayer.load { (error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Set the viewpoint to the full extent of all layers.
                self.mapView.setViewpointGeometry(featureLayer.fullExtent!)
            }
        }
        // Add each layer to the map.
        mapView.map?.operationalLayers.add(featureLayer)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CustomDictionaryStyleViewController"]
    }
}
