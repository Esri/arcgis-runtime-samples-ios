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

class FeatureCollectionLayerFromPortalViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .oceans())
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "FeatureCollectionLayerFromPortalViewController"
        ]
        // Create a portal item with portal item ID.
        let featureCollectionPortalItemID = "32798dfad17942858d5eef82ee802f0b"
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        let portalItem = AGSPortalItem(portal: portal, itemID: featureCollectionPortalItemID)
        // Load the portal item and add feature collection layer to the map.
        portalItem.load { [weak self] (error: Error?) in
            guard let self = self else { return }
            if portalItem.type == .featureCollection {
                let featureCollectionLayer = AGSFeatureCollectionLayer(
                    featureCollection: AGSFeatureCollection(item: portalItem)
                )
                self.mapView.map?.operationalLayers.add(featureCollectionLayer)
                self.mapView.setViewpointScale(1e8)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
}
