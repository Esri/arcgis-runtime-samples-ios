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
            mapView.map = makeMap()
        }
    }
    
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
        ProcessInfo.processInfo.globallyUniqueString,
        isDirectory: true
    )
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        // Create a map with oceans basemap.
        let map = AGSMap(basemap: .oceans())
        // Load ENC exchange set from bundle.
        let fileURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "ExchangeSetwithoutUpdates") ?? []
        let directoryURL = fileURLs.first!.deletingLastPathComponent()
        
        AGSENCEnvironmentSettings.shared().resourceDirectory = directoryURL
        AGSENCEnvironmentSettings.shared().sencDataDirectory = temporaryDirectoryURL
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        
        let catalogFileURL = fileURLs.filter { $0.lastPathComponent == "CATALOG.031" }
//        let catalogFileURL = temporaryDirectoryURL.appendingPathComponent("CATALOG.031")
        let ENCExchangeSet = AGSENCExchangeSet(fileURLs: catalogFileURL)
        
//        let us = try? FileManager.default.contentsOfDirectory(at: temporaryDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        ENCExchangeSet.load { [weak self] error in  //, unowned ENCExchangeSet
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                var ENCLayers = [AGSENCLayer]()
                let loadGroup = DispatchGroup()
                // Create a list of ENC layers and add them to the map
                for dataset in ENCExchangeSet.datasets {
                    let layer = AGSENCLayer(cell: AGSENCCell(dataset: dataset))
                    ENCLayers.append(layer)
                    loadGroup.enter()
                    layer.load { [weak self] error in
                        defer {
                            loadGroup.leave()
                        }
                        if let error = error {
                            self?.presentAlert(error: error)
                        }
                    }
                }
                
                map.operationalLayers.addObjects(from: ENCLayers)
                
                // Zoom to the combined extent of all ENC layers.
                loadGroup.notify(queue: .main) {
                    if let completeExtent = AGSGeometryEngine.combineExtents(ofGeometries: ENCLayers.compactMap { $0.fullExtent }) {
                        self.mapView.setViewpoint(AGSViewpoint(targetExtent: completeExtent), completion: nil)
                    }
                }
            }
        }
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AddENCExchangeSetViewController"]
    }
    
    deinit {
        DispatchQueue.global(qos: .utility).async { [temporaryDirectoryURL = self.temporaryDirectoryURL] in
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }
    }
}
