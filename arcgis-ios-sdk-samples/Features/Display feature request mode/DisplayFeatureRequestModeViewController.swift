// Copyright 2021 Esri.
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

class DisplayFeatureRequestModeViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(latitude: 45.5266, longitude: -122.6219, scale: 6000))
        }
    }
    @IBOutlet weak var modeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var populateBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var statusLabel: UILabel!
    
    private static let featureServiceURL = "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Trees_of_Portland/FeatureServer/0"
    let featureTable = AGSServiceFeatureTable(url: URL(string: featureServiceURL)!)
    
    private enum FeatureRequestMode: CaseIterable {
        case cache, noCache, manualCache
        
        var title: String {
            switch self {
            case .cache:
                return "Cache"
            case .noCache:
                return "No cache"
            case .manualCache:
                return "Manual cache"
            }
        }
        
        var mode: AGSFeatureRequestMode {
            switch self {
            case .cache:
                return .onInteractionCache
            case .noCache:
                return .onInteractionNoCache
            case .manualCache:
                return .manualCache
            }
        }
    }
    
    /// Prompt mode selection.
    @IBAction func modeButonTapped(_ button: UIBarButtonItem) {
        // Set up action sheets.
        let alertController = UIAlertController(
            title: "Choose a feature request mode.",
            message: nil,
            preferredStyle: .actionSheet
        )
        // Create an action for each mode.
        FeatureRequestMode.allCases.forEach { mode in
            let action = UIAlertAction(title: mode.title, style: .default) { [self] _ in
                changeFeatureRequestMode(to: mode.mode)
                let message = "\(mode.title) enabled."
                setStatus(message: message)
            }
            alertController.addAction(action)
        }
        // Add a cancel action.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = modeBarButtonItem
        present(alertController, animated: true)
    }
    
    /// Populate for manual cache mode.
    @IBAction func populateManualCache(_ button: UIBarButtonItem) {
        // Set query parameters.
        let params = AGSQueryParameters()
        // Query for all tree conditions except "dead" with coded value '4'.
        params.whereClause = "Condition < '4'"
        // Show the progress HUD.
        UIApplication.shared.showProgressHUD(message: "Populating")
        // Populate features based on the query.
        self.featureTable.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
            guard let self = self else { return }
            // Hide progress HUD.
            UIApplication.shared.hideProgressHUD()
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Display the number of features found.
                let message = "Populated \(result?.featureEnumerator().allObjects.count ?? 0) features."
                self.setStatus(message: message)
            }
        }
    }
    
    /// Set the appropriate feature request mode.
    private func changeFeatureRequestMode(to mode: AGSFeatureRequestMode) {
        // Enable or disable the populate bar button item when appropriate.
        if mode == .manualCache {
            populateBarButtonItem.isEnabled = true
        } else {
            populateBarButtonItem.isEnabled = false
        }
        let map = mapView.map
        map?.operationalLayers.removeAllObjects()
        // Set the request mode.
        featureTable.featureRequestMode = mode
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // Add the feature layer to the map.
        map?.operationalLayers.add(featureLayer)
        mapView.map = map
    }
    
    /// Set the status.
    private func setStatus(message: String) {
        statusLabel.text = message
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStatus(message: "Select a feature request mode.")
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayFeatureRequestModeViewController"]
    }
}
