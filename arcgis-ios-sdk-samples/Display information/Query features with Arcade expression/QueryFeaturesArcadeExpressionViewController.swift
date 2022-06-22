// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class QueryFeaturesArcadeExpressionViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.touchDelegate = self
            
        }
    }
    
    func makeMap() -> AGSMap {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        let portalItem = AGSPortalItem(portal: portal, itemID: "14562fced3474190b52d315bc19127f6")
        let map = AGSMap(item: portalItem)
        map.load() { error in
            map.operationalLayers.forEach { layer in
                let currentLayer = layer as? AGSLayer
                if currentLayer?.name == "Crime in the last 60 days" || currentLayer?.name == "Police Stations" {
                    currentLayer?.isVisible = false
                }
            }
        }
        return map
    }
    
    func queryFeaturesWithArcadeExpression() {
        
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "QueryFeaturesArcadeExpressionViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension QueryFeaturesArcadeExpressionViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss any presenting callout.
        mapView.callout.dismiss()
        // Identify features at the tapped location.
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { results, error in
            if results?.isEmpty {
                return
            } else if let elements = results?.first?.geoElements {
                let firstElement = elements.first as? AGSArcGISFeature
                
            }
        }
        mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12.0, returnPopupsOnly: false, maximumResults: 10) { [weak self] result in
            guard let self = self else { return }
            self.mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
            let elementList =
        }
    }
}
