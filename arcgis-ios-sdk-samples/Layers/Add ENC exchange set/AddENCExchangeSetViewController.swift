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
    
    func getTemporaryDocumentDirectoryURL(subfolderURL: URL) -> URL? {
        do {
            let tempDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: subfolderURL,
                create: true
            )
//            .appendingPathComponent("ENC_ROOT", isDirectory: true)
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            return tempDirectory
        } catch {
            return nil
        }
    }
    
    var temporaryDocumentDirectory: URL!
    
    let temporaryDirectory: URL = FileManager.default.temporaryDirectory
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        // Create a map with oceans basemap.
        let map = AGSMap(basemap: .oceans())
        // Load ENC exchange set from bundle.
        let fileURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "ExchangeSetwithoutUpdates")!
        let hydrographyDirectory = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "hydrography")!.first!.deletingLastPathComponent()
//        let directoryURL = fileURLs.first!.deletingLastPathComponent()
//
//        guard let url = getTemporaryDocumentDirectoryURL(subfolderURL: directoryURL) else { return map }
//        temporaryDocumentDirectory = url
//        try? FileManager.default.copyItem(at: directoryURL, to: temporaryDocumentDirectory)
        
        AGSENCEnvironmentSettings.shared().resourceDirectory = hydrographyDirectory
        AGSENCEnvironmentSettings.shared().sencDataDirectory = temporaryDirectory
        
        let catalogURL = fileURLs.filter { $0.lastPathComponent == "CATALOG.031" }
//        let catalogURL = [temporaryDocumentDirectory.appendingPathComponent("CATALOG.031")]
        let encExchangeSet = AGSENCExchangeSet(fileURLs: catalogURL)
        
//        let us = try? FileManager.default.contentsOfDirectory(at: temporaryDocumentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        encExchangeSet.load { [weak self] error in  //, unowned ENCExchangeSet
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                var ENCLayers = [AGSENCLayer]()
                let loadGroup = DispatchGroup()
                // Create a list of ENC layers and add them to the map
                for dataset in encExchangeSet.datasets {
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
        DispatchQueue.global(qos: .utility).async { [temporaryDirectoryURL = self.temporaryDocumentDirectory] in
            guard let url = temporaryDirectoryURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }
}
