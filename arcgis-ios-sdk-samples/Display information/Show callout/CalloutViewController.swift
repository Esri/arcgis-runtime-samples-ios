// Copyright 2016 Esri.
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

class CalloutViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with topographic basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            
            // Set the map view's touch delegate to `self` in order to get
            // tap notifications.
            mapView.touchDelegate = self
            
            // Set the map view's viewpoint.
            mapView.setViewpointCenter(AGSPoint(x: -1.2e7, y: 5e6, spatialReference: .webMercator()), scale: 4e7)
            
            // Configure the map view's callout to hide accessory button.
            mapView.callout.isAccessoryButtonHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CalloutViewController"]
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // User tapped on the map.
        if mapView.callout.isHidden {
            // Show the callout with the coordinates of the tapped location.
            mapView.callout.title = "Location"
            // Project the tapped location point to WGS 84 spatial reference.
            let location = AGSGeometryEngine.projectGeometry(mapPoint, to: .wgs84()) as! AGSPoint
            mapView.callout.detail = String(format: "x: %.2f, y: %.2f", location.x, location.y)
            mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
        } else {
            // Hide the callout.
            mapView.callout.dismiss()
        }
    }
}
