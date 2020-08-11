// Copyright 2020 Esri.
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

class ShowPopupViewController: UIViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    var featureLayer: AGSFeatureLayer?
    
    func makeMap() -> AGSMap {
        // Create a map using a URL.
        let mapURL = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=fb788308ea2e4d8682b9c05ef641f273")!
        let map = AGSMap(url: mapURL)!
        // Load the map.
        map.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Set touch delegate.
                self.mapView.touchDelegate = self
                // Get the feature layer.
                self.featureLayer = map.operationalLayers.firstObject as? AGSFeatureLayer
            }
        }
        return map
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard let featureLayer = self.featureLayer else { return }
        // Identify the specified feature layer.
        mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            guard let self = self else { return }
            if let error = result.error {
                self.presentAlert(error: error)
            } else if !result.popups.isEmpty {
                // Unselect the previous feature.
                featureLayer.clearSelection()
                // Select the new feature.
                let features = result.geoElements as? [AGSFeature]
                let selectedFeature = features?.first
                featureLayer.select(selectedFeature!)
                // Display a popup only if it exists.
                let popupsViewController = AGSPopupsViewController(popups: result.popups)
                // Display the popup as a formsheet -- specified for iPads.
                popupsViewController.modalPresentationStyle = .formSheet
                // Present the popup.
                popupsViewController.delegate = self
                self.present(popupsViewController, animated: true)
            }
        }
    }
    
    // MARK: - AGSPopupsViewControllerDelegate methods
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        // Dismiss the popups view controller.
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowPopupViewController"]
    }
}
