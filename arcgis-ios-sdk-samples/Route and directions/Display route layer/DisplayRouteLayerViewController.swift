// Copyright 2022 Esri.
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

class DisplayRouteLayerViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with basemap.
            mapView.map = makeMap()
            // Set the viewpoint.
            let viewpoint = AGSViewpoint(latitude: 45.2281, longitude: -122.8309, scale: 6e5)
            mapView.setViewpoint(viewpoint)
        }
    }
    
    @IBOutlet var directionsBarButtonItem: UIBarButtonItem!
    
    var directions = [String]()
    
    func makeMap() -> AGSMap {
        // Set the basemap.
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        // Set the portal.
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        // Create the portal item with the item ID for route data in Portland, OR.
        let item = AGSPortalItem(portal: portal, itemID: "0e3c8e86b4544274b45ecb61c9f41336")
        // Create a collection of features using the item.
        let featureCollection = AGSFeatureCollection(item: item)
        // Load the feature collection.
        loadFeatureCollection(featureCollection)
        // Create a feature collection layer using the feature collection.
        let featureCollectionLayer = AGSFeatureCollectionLayer(featureCollection: featureCollection)
        // Set the feature collection layers to the map's operational layers.
        map.operationalLayers.setArray([featureCollectionLayer])
        return map
    }
    
    func loadFeatureCollection(_ featureCollection: AGSFeatureCollection) {
        // Load the feature collection.
        featureCollection.load { [weak self] error in
            guard let self = self else { return }
            // Present an error if loading was unsuccessful.
            if let error = error {
                self.presentAlert(error: error)
            } else {
                guard
                    // Make an array of all the feature collection tables.
                    let tables = featureCollection.tables as? [AGSFeatureCollectionTable],
                    // Get the table that contains the turn by turn directions.
                    let directionsTable = tables.first(where: { $0.tableName == "DirectionPoints" })
                else { return }
                // Create an array of all the features in the table.
                let features = directionsTable.featureEnumerator().allObjects
                // Set the array of directions.
                self.directions = features.compactMap { $0.attributes["DisplayText"] as? String }
                // Enable the directions bar button item.
                self.directionsBarButtonItem.isEnabled = true
            }
        }
    }
    
    @IBSegueAction
    func makeDirectionsViewController(_ coder: NSCoder) -> DisplayDirectionsViewController? {
        DisplayDirectionsViewController(
            coder: coder,
            directions: directions
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayRouteLayerViewController", "DisplayDirectionsViewController"]
    }
}
