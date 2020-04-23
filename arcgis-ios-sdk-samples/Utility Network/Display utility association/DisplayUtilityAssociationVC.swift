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

class DisplayUtilityAssociationVC: UIViewController {
    // Set the map.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapType: .topographicVector, latitude: -9812698.37297436, longitude: 5131928.33743317, levelOfDetail: 22)
            mapView.graphicsOverlays.add(associationsOverlay)
        }
    }
    
    private let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    private let maxScale = 2000
    private var associationsOverlay = AGSGraphicsOverlay()
    
    func loadUtilityNetwork() {
        utilityNetwork.load { [weak self] error in
            if let error = error {
//                self?.setStatus(message: "Loading Utility Network Failed")
                self?.presentAlert(error: error)
            } else {
//                var edges = utilityNetwork.definition.networkSources.filter {$0 is AGSUtilityNetworkSourceTypeEdge}
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayUtilityAssociationVC"]
    }
}
