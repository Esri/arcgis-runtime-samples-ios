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
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            // Initialize the map.
            mapView.map = AGSMap(basemap: .topographic())
            
            //let geodatabase = AGSGeodatabase(fileURL: geodatabaseURL)
        }
    }
    
    func displayLayersFromGeodatabase() {
        let geodatabaseURL = Bundle.main.url(forResource: "militaryoverlay", withExtension: ".geodatabase")!
        let generatedGeodatabase = AGSGeodatabase(fileURL: geodatabaseURL) 
        generatedGeodatabase.load { [weak self] (error: Error?) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.mapView.map?.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(generatedGeodatabase.geodatabaseFeatureTables) { (success: Bool) in
                    if success {
                        for featureTable in generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self.mapView.map?.operationalLayers.add(featureLayer)
                            }
                        }
                        self.presentAlert(message: "Now showing data from geodatabase")
                        
                        // hide the extent view
                        self.extentView.isHidden = true
                        // disable the download button
                        self.downloadBBI.isEnabled = false
                    }
                    // unregister geodatabase as the sample wont be editing or syncing features
                    self.syncTask.unregisterGeodatabase(generatedGeodatabase)
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
