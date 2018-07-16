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

class DisplayGridViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayGridViewController", "DisplayGridSettingsViewController"]

        // Initialize map with imagery basemap
        let map = AGSMap(basemap: AGSBasemap.imagery())
        
        // Set initial viewpoint
        let center = AGSPoint(x: -7702852.905619, y: 6217972.345771, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: center, scale: 23227)
        
        // Assign map to the map view
        mapView.map = map
        
        // Add lat long grid
        mapView.grid = AGSLatitudeLongitudeGrid()
    }
    
    var settingsViewController: DisplayGridSettingsViewController?
    
    func makeSettingsViewController() -> DisplayGridSettingsViewController {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "DisplayGridSettingsViewController") as? DisplayGridSettingsViewController else {
            fatalError()
        }
        
        viewController.mapView = mapView
        viewController.modalPresentationStyle = .popover
        
        return viewController
    }
    
    @IBAction func showSettings(_ sender: Any) {
        let settingsViewController: DisplayGridSettingsViewController
        if let viewController = self.settingsViewController {
            settingsViewController = viewController
        } else {
            settingsViewController = makeSettingsViewController()
            self.settingsViewController = settingsViewController
        }
        settingsViewController.preferredContentSize = {
            let height: CGFloat
            if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
                height = 350
            } else {
                height = 250
            }
            return CGSize(width: 375, height: height)
        }()
        settingsViewController.presentationController?.delegate = self
        if let popoverPC = settingsViewController.popoverPresentationController {
            popoverPC.barButtonItem = sender as? UIBarButtonItem
            popoverPC.passthroughViews = [mapView]
        }
        present(settingsViewController, animated: true)
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
