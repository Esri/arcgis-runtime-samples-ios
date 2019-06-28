//
// Copyright 2017 Esri.
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

class DisplayGridViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "DisplayGridViewController",
            "DisplayGridSettingsViewController",
            "OptionsTableViewController",
            "ColorPickerViewController"
        ]

        // Initialize map with imagery basemap
        let map = AGSMap(basemap: .imagery())
        
        // Set initial viewpoint
        let center = AGSPoint(x: -7702852.905619, y: 6217972.345771, spatialReference: .webMercator())
        map.initialViewpoint = AGSViewpoint(center: center, scale: 23227)
        
        // Assign map to the map view
        mapView.map = map
        
        // Add lat long grid
        mapView.grid = AGSLatitudeLongitudeGrid()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? DisplayGridSettingsViewController {
            controller.mapView = mapView
            controller.preferredContentSize = {
                let height: CGFloat
                if traitCollection.horizontalSizeClass == .regular,
                    traitCollection.verticalSizeClass == .regular {
                    height = 350
                } else {
                    height = 250
                }
                return CGSize(width: 375, height: height)
            }()
            navController.presentationController?.delegate = self
        }
    }
}

extension DisplayGridViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
