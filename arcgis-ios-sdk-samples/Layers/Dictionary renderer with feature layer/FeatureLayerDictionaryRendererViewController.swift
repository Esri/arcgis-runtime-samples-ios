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

class FeatureLayerDictionaryRendererViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize the map.
            mapView.map = AGSMap(basemap: .topographic())
            
            // Display symbology using a geodatabase.
            displayLayersFromGeodatabase()
        }
    }
    
    func displayLayersFromGeodatabase() {
        // Load geodatabase from shared resources.
        let geodatabaseURL = Bundle.main.url(forResource: "militaryoverlay", withExtension: ".geodatabase")!
        let generatedGeodatabase = AGSGeodatabase(fileURL: geodatabaseURL)
        
        // Instantiate and load symbol dictionary from shared resources.
        let styleURL = Bundle.main.url(forResource: "mil2525d", withExtension: "stylx")
        let dictionarySymbol = AGSDictionarySymbolStyle(url: styleURL!)
        dictionarySymbol.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                return
            }
        }
        
        // Once geodatabase is done loading, create feature layers from each feature table.
        generatedGeodatabase.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                for featureTable in generatedGeodatabase.geodatabaseFeatureTables {
                    // Create a feature layer from the feature table.
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    // Set the minimum visibility scale.
                    featureLayer.minScale = 1000000
                    featureLayer.load { (error: Error?) in
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            // Set the viewpoint to the full extent of all layers.
                            self?.mapView.setViewpointGeometry(featureLayer.fullExtent!)
                        }
                    }
                    // Add each layer to the map.
                    self!.mapView.map?.operationalLayers.add(featureLayer)
                    // Display features from the layer using mil2525d symbols.
                    featureLayer.renderer = AGSDictionaryRenderer(dictionarySymbolStyle: dictionarySymbol)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerDictionaryRendererViewController"]
    }
}
