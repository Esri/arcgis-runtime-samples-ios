// Copyright 2021 Esri
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

class EditAttributesContingentValuesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    // The geodatabase used by this sample.
    let geodatabase: AGSGeodatabase!
    
    required init?(coder: NSCoder) {
        // Create a URL leading to the resource.
        let geodatabaseURL = Bundle.main.url(forResource: "BirdNestsMGDB", withExtension: "geodatabase")!
        do {
            // Create a temporary directory URL.
            let temporaryDirectoryURL = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: geodatabaseURL,
                create: true
            )
            // Create a temporary URL where the geodatabase URL can be copied to.
            let temporaryGeodatabaseURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            try FileManager.default.copyItem(at: geodatabaseURL, to: temporaryGeodatabaseURL)
            // Create the geodatabase with the URL.
            geodatabase = AGSGeodatabase(fileURL: temporaryGeodatabaseURL)
        } catch {
            print("Error setting up geodatabase: \(error)")
            geodatabase = nil
        }
        
        super.init(coder: coder)
        
        // Load the geodatabase.
        geodatabase?.load { [weak self] (error) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            self?.geodatabaseDidLoad(with: result)
        }
    }
    
    deinit {
        if let geodatabase = geodatabase {
            geodatabase.close()
            try? FileManager.default.removeItem(at: geodatabase.fileURL)
        }
    }
    
    // Called in response to the geodatabase load operation completing.
    func geodatabaseDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
//            guard let map = self.mapView.map else { return }
            if let featureTable = self.geodatabase.geodatabaseFeatureTables[0] as? AGSArcGISFeatureTable {
                let contingentValuesDefinition = featureTable.contingentValuesDefinition
                contingentValuesDefinition.load { error in
                    if let feature = featureTable.createFeature() as? AGSArcGISFeature {
                        feature.attributes["Activity"] = "OCCUPIED"
                        feature.attributes["Protection"] = "ENDANGERED"
                        feature.attributes["BufferSize"] = 100
                        let contingentValueResults = featureTable.contingentValues(with: feature, field: "Activity")
                    }
                }
            }
            
            // Add the feature layers to the map.
//            map.operationalLayers.addObjects(from: featureLayers)
//            // Create annotation layers from tables in the geodatabase.
//            let annotationTableNames = ["ParcelLinesAnno_1", "Loudoun_Address_PointsAnno_1"]
//            let annotationTables = annotationTableNames.compactMap { self.geodatabase.geodatabaseAnnotationTable(withTableName: $0) }
//            let annotationLayers = annotationTables.map(AGSAnnotationLayer.init)
//            // Add the annotation layers to the map.
//            map.operationalLayers.addObjects(from: annotationLayers)
        case .failure(let error):
            self.presentAlert(error: error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttributesContingentValuesViewController"]
    }
}
