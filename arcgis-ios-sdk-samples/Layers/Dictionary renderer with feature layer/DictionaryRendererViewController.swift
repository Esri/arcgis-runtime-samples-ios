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

class DictionaryRendererViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize the map.
            mapView.map = AGSMap(basemap: .topographic())
            
            // Initiate geodatabase.
            displayLayersFromGeodatabase()
        }
    }
    
    func displayLayersFromGeodatabase() {
        // Load geodatabase from shared resources.
        let geodatabaseURL = Bundle.main.url(forResource: "militaryoverlay", withExtension: ".geodatabase")!
        let generatedGeodatabase = AGSGeodatabase(fileURL: geodatabaseURL)
        // Instantiate and load a symbol dictionary.
        let dictionarySymbol = AGSDictionarySymbolStyle(name: "mil2525d")
        dictionarySymbol.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                return
            }
        }
        
        // Once geodatabase is done loading, load feature layers.
        generatedGeodatabase.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                for featureTable in generatedGeodatabase.geodatabaseFeatureTables {
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.load { [weak self] (error: Error?) in
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            let envelopeBuilder = AGSEnvelopeBuilder(envelope: featureLayer.fullExtent)
                            envelopeBuilder.union(with: featureLayer.fullExtent!)
                            self?.mapView.setViewpointGeometry(envelopeBuilder.toGeometry())
                        }
                    }
                    featureLayer.minScale = 1000000
                    self!.mapView.map?.operationalLayers.add(featureLayer)
                    featureLayer.renderer = AGSDictionaryRenderer(dictionarySymbolStyle: dictionarySymbol)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DictionaryRendererViewController"]
    }
}
