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
    
    var previousFeature: AGSArcGISFeature?
    var detail: String?
    
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
    
    func evaluateArcadeInCallout(for feature: AGSArcGISFeature, at mapPoint: AGSPoint) {
        if self.previousFeature == nil {
            let expressionValue = "var crimes = FeatureSetByName($map, 'Crime in the last 60 days');\n" + "return Count(Intersects($feature, crimes));"
            let expression = AGSArcadeExpression(expression: expressionValue)
            let evaluator = AGSArcadeEvaluator(expression: expression, profile: .formCalculation)
            guard let map = mapView.map else { return }
            let profileVariables = ["$feature": feature, "$map": map]
            evaluator.evaluate(withProfileVariables: profileVariables) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result, let crimeCount = result.cast(to: .string) as? String {
                    self.detail = "Crimes in the last 60 days: \(crimeCount)"
                    self.previousFeature = feature
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
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
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] results, error in
            guard let results = results, let self = self else { return }
            if let elements = results.first?.geoElements {
                guard let identifiedFeature = elements.first as? AGSArcGISFeature else { return }
                self.evaluateArcadeInCallout(for: identifiedFeature, at: mapPoint)
                self.mapView.callout.isAccessoryButtonHidden = true
                self.mapView.callout.detail = self.detail
                self.mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
}
