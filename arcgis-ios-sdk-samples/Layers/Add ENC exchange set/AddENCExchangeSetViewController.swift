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
            mapView.map = AGSMap(basemap: .oceans())
        }
    }
    
    /// Load the ENC dataset to the map view.
    ///
    /// - Parameter mapView: The map view managed by the view controller.
    func addENCExchangeSet(mapView: AGSMapView) {
        guard let map = mapView.map else { return }
        // Load catalog file in ENC exchange set from bundle.
        let catalogURL = Bundle.main.url(
            forResource: "CATALOG",
            withExtension: "031",
            subdirectory: "ExchangeSetwithoutUpdates/ExchangeSetwithoutUpdates/ENC_ROOT"
        )!
        let encExchangeSet = AGSENCExchangeSet(fileURLs: [catalogURL])
        
        // URL to the "hydrography" data folder that contains the "S57DataDictionary.xml" file.
        let hydrographyDirectory = Bundle.main.url(
            forResource: "S57DataDictionary",
            withExtension: "xml",
            subdirectory: "hydrography/hydrography"
        )!
        .deletingLastPathComponent()
        // Set environment settings for loading the dataset.
        let environmentSettings = AGSENCEnvironmentSettings.shared()
        environmentSettings.resourceDirectory = hydrographyDirectory
        // The SENC data directory is for temporarily storing generated files.
        environmentSettings.sencDataDirectory = FileManager.default.temporaryDirectory
        
        encExchangeSet.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                var ENCLayers = [AGSENCLayer]()
                let loadGroup = DispatchGroup()
                // A reference to the last error occurred, if there is any.
                var loadError: Error?
                // Create a list of ENC layers and load each layer.
                encExchangeSet.datasets.forEach { dataset in
                    let layer = AGSENCLayer(cell: AGSENCCell(dataset: dataset))
                    ENCLayers.append(layer)
                    loadGroup.enter()
                    layer.load { error in
                        defer { loadGroup.leave() }
                        loadError = error
                    }
                }
                // Add layers to the map.
                map.operationalLayers.addObjects(from: ENCLayers)
                
                // Zoom to the combined extent of all ENC layers after they are loaded.
                loadGroup.notify(queue: .main) { [weak self] in
                    if let completeExtent = AGSGeometryEngine.combineExtents(ofGeometries: ENCLayers.compactMap { $0.fullExtent }) {
                        self?.mapView.setViewpoint(AGSViewpoint(targetExtent: completeExtent), completion: nil)
                    } else if let error = loadError {
                        self?.presentAlert(error: error)
                    }
                }
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
        // Remove all files in tmp folder.
        DispatchQueue.global(qos: .utility).async {
            let tmpURL = FileManager.default.temporaryDirectory
            if let tmpDirectory = try? FileManager.default.contentsOfDirectory(
                at: tmpURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) {
                tmpDirectory.forEach { file in
                    try? FileManager.default.removeItem(atPath: file.path)
                }
            }
        }
    }
}
