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

class AddENCExchangeSetViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISOceans)
        }
    }
    
    /// A URL to the temporary folder for SENC data directory.
    let temporaryURL: URL = {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        // Create and return the full, unique URL to the temporary folder.
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }()
    
    /// Load the ENC dataset and add to the map view.
    ///
    /// - Parameter mapView: The map view managed by the view controller.
    func addENCExchangeSet(mapView: AGSMapView) {
        guard let map = mapView.map else { return }
        // Load catalog file in ENC exchange set from bundle.
        let catalogURL = Bundle.main.url(
            forResource: "CATALOG",
            withExtension: "031",
            subdirectory: "ExchangeSetWithoutUpdates/ENC_ROOT"
        )!
        let encExchangeSet = AGSENCExchangeSet(fileURLs: [catalogURL])
        
        // URL to the "hydrography" data folder that contains the "S57DataDictionary.xml" file.
        let hydrographyDirectory = Bundle.main.url(
            forResource: "S57DataDictionary",
            withExtension: "xml",
            subdirectory: "hydrography"
        )!
        .deletingLastPathComponent()
        // Set environment settings for loading the dataset.
        let environmentSettings = AGSENCEnvironmentSettings.shared()
        environmentSettings.resourceDirectory = hydrographyDirectory
        // The SENC data directory is for temporarily storing generated files.
        environmentSettings.sencDataDirectory = temporaryURL
        
        encExchangeSet.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Create a list of ENC layers from datasets.
                let encLayers = encExchangeSet.datasets.map { AGSENCLayer(cell: AGSENCCell(dataset: $0)) }
                // Add layers to the map.
                map.operationalLayers.addObjects(from: encLayers)
                mapView.setViewpoint(AGSViewpoint(latitude: -32.5, longitude: 60.95, scale: 1e5), completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AddENCExchangeSetViewController"]
        addENCExchangeSet(mapView: mapView)
    }
    
    deinit {
        // Recursively remove all files in the sample-specific
        // temporary folder and the folder itself.
        try? FileManager.default.removeItem(at: temporaryURL)
    }
}
