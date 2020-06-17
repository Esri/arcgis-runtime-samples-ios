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
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    var featureLayer: AGSFeatureLayer?
    var popupsViewController: AGSPopupsViewController?
    
    func makeMap() -> AGSMap {
        let mapURL = URL(string: "https://runtime.maps.arcgis.com/home/item.html?id=ccf828425b5a456b90eb75cf72278e13")!
        let map = AGSMap(url: mapURL)
        map?.initialViewpoint = AGSViewpoint(latitude: 47.6062, longitude: -122.3321, scale: 2e4)
        map?.load { [weak self] (error) in
        guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                //set touch delegate
                self.mapView.touchDelegate = self
                self.featureLayer = map?.operationalLayers[0] as? AGSFeatureLayer
            }
        }
        return map!
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.mapView.identifyLayer(featureLayer!, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            guard let self = self else { return }
            if let error = result.error {
                self.presentAlert(error: error)
            } else {
                self.popupsViewController = AGSPopupsViewController(popups: result.popups)
                self.popupsViewController?.modalPresentationStyle = .formSheet
                self.present(self.popupsViewController!, animated: true)
                self.popupsViewController?.delegate = self
            }
        }
    }
    
    // MARK: - AGSPopupsViewControllerDelegate methods
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        // Dismiss the popups view controller.
        self.dismiss(animated: true)
        // Reset the popups view controller
        self.popupsViewController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowPopupViewController"]
    }
}
