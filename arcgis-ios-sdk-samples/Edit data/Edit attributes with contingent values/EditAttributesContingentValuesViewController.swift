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
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            loadMobileMapPackage()
        }
    }
    
    /// The mobile map package used by this sample.
    let mobileMapPackage = AGSMobileMapPackage(fileURL: Bundle.main.url(forResource: "NestingBirdsContingentValues", withExtension: "mmpk")!)
    
    /// Initiates loading of the mobile map package.
    func loadMobileMapPackage() {
        mobileMapPackage.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
//                self.mapView.map
                let map = self.mobileMapPackage.maps.first
                if let featureTable = map?.tables.first(where: { $0 is AGSFeatureTable }) as? AGSFeatureTable {
                    featureTable.load { error in
                        let contingentValuesDefinition = featureTable.contin
                        let fieldGroups =
                }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttributesContingentValuesViewController"]
    }
}
