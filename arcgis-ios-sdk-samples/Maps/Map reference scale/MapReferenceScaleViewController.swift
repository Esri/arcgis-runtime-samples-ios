//
// Copyright © 2019 Esri.
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
//

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Map Reference Scale
/// sample.
class MapReferenceScaleViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let portal = AGSPortal(url: URL(string: "https://runtime.maps.arcgis.com")!, loginRequired: false)
        let portalItem = AGSPortalItem(portal: portal, itemID: "3953413f3bd34e53a42bf70f2937a408")
        return AGSMap(item: portalItem)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "MapReferenceScaleViewController",
            "MapReferenceScaleSettingsViewController",
            "MapReferenceScaleLayerSelectionViewController"
        ]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navigationController = segue.destination as? UINavigationController,
            let settingsViewController = navigationController.topViewController as? MapReferenceScaleSettingsViewController {
            settingsViewController.map = mapView.map
            settingsViewController.mapScale = mapView.mapScale
            settingsViewController.delegate = self
        }
    }
}

extension MapReferenceScaleViewController: MapReferenceScaleSettingsViewControllerDelegate {
    func mapReferenceScaleSettingsViewControllerDidChangeMapScale(_ controller: MapReferenceScaleSettingsViewController) {
        mapView.setViewpointScale(controller.mapScale)
    }
    
    func mapReferenceScaleSettingsViewControllerDidFinish(_ controller: MapReferenceScaleSettingsViewController) {
        dismiss(animated: true)
    }
}
