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
    /// The URL to the restaurants feature table.
    let restaurantFeatureTableURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Redlands_Restaurants/FeatureServer/0")!
    /// The URL to the symbol style dictionary from shared resources.
    let restaurantStyleURL = Bundle.main.url(forResource: "Restaurant", withExtension: "stylx")!
    
    /// A feature layer that contains custom symbol style.
    lazy var featureLayer: AGSFeatureLayer = {
        // Create restaurants feature table from the feature service URL.
        let restaurantFeatureTable = AGSServiceFeatureTable(url: restaurantFeatureTableURL)
        // Create the restaurants layer.
        let featureLayer = AGSFeatureLayer(featureTable: restaurantFeatureTable)
        // Open the custom style file.
        let restaurantStyle = AGSDictionarySymbolStyle(url: restaurantStyleURL)
        // Create the dictionary renderer from the style file.
        let dictRenderer = AGSDictionaryRenderer(dictionarySymbolStyle: restaurantStyle)
        // Apply the dictionary renderer to a feature layer.
        featureLayer.renderer = dictRenderer
        featureLayer.load { (error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Set the viewpoint to the full extent of all layers.
                self.mapView.setViewpointGeometry(featureLayer.fullExtent!)
            }
        }
        return featureLayer
    }()
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Add the feature layer to the map.
            mapView.map?.operationalLayers.add(featureLayer)
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streets())
        return map
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CustomDictionaryStyleViewController"]
    }
}
