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
            // Set the touch delegate.
            mapView.touchDelegate = self
        }
    }
    
    /// The Arcade expression evaluation operation.
    var evaluateOperation: AGSCancelable?
    
    /// Make and load a map.
    func makeMap() -> AGSMap {
        // Create a portal item with the portal and item ID.
        let portalItem = AGSPortalItem(portal: .arcGISOnline(withLoginRequired: false), itemID: "539d93de54c7422f88f69bfac2aebf7d")
        // Make a map with the portal item.
        let map = AGSMap(item: portalItem)
        return map
    }
    
    /// Evaluate the Arcade expression for the selected feature at the map point.
    func evaluateArcadeInCallout(for feature: AGSArcGISFeature, at mapPoint: AGSPoint) {
        // Instantiate a string containing the Arcade expression.
        let expressionValue =
        """
        var crimes = FeatureSetByName($map, 'Crime in the last 60 days');
        return Count(Intersects($feature, crimes));
        """
        // Create an Arcade expression using the string.
        let expression = AGSArcadeExpression(expression: expressionValue)
        // Create an Arcade evaluator with the Arcade expression and an Arcade profile.
        let evaluator = AGSArcadeEvaluator(expression: expression, profile: .formCalculation)
        guard let map = mapView.map else { return }
        let profileVariables = ["$feature": feature, "$map": map]
        // Show progress hud.
        UIApplication.shared.showProgressHUD(message: "Evaluating")
        evaluateOperation?.cancel()
        // Get the Arcade evaluation result given the previously set profile variables.
        evaluateOperation = evaluator.evaluate(withProfileVariables: profileVariables) { [weak self] result, error in
            guard let self = self else { return }
            // Dismiss progress hud.
            UIApplication.shared.hideProgressHUD()
            // Enable user interaction.
            self.mapView.isUserInteractionEnabled = true
            if let result = result, let crimeCount = result.cast(to: .string) as? String {
                self.mapView.setViewpointCenter(mapPoint)
                // Hide the accessory button.
                self.mapView.callout.isAccessoryButtonHidden = true
                // Set the detail text.
                self.mapView.callout.detail = String(format: "Crimes in the last 60 days: %@", crimeCount)
                // Prompt the callout at the map point.
                self.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
            } else if let error = error {
                // Present an error if needed.
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
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
            guard let self = self else { return }
            // Get the selected feature.
            if let elements = results?.first?.geoElements, let identifiedFeature = elements.first as? AGSArcGISFeature {
                // Disable user interaction after a feature has been identified.
                self.mapView.isUserInteractionEnabled = false
                // Evaluate the Arcade for the given feature.
                self.evaluateArcadeInCallout(for: identifiedFeature, at: mapPoint)
            } else if let error = error {
                // Present an error alert if needed.
                self.presentAlert(error: error)
            }
        }
    }
}
