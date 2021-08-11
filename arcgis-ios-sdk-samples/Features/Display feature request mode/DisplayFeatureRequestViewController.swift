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
            mapView.setViewpoint(AGSViewpoint(latitude: 45.5185, longitude: -122.5965, scale: 6000))
        }
    }
    @IBOutlet weak var modeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var populateBarButtonItem: UIBarButtonItem!
    
    private static let featureServiceURL = "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Trees_of_Portland/FeatureServer/0"
//    private static let featureServiceSFURL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"
    let featureTable = AGSServiceFeatureTable(url: URL(string: featureServiceURL)!)
//    let featureTableSF = AGSServiceFeatureTable(url: URL(string: featureServiceSFURL)!)
    
    private enum FeatureRequestMode: CaseIterable {
        case undefined, cache, noCache, manualCache
        
        var title: String {
            switch self {
            case .undefined:
                return "Undefined"
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
            case .undefined:
                return .undefined
            case .cache:
                return .onInteractionCache
            case .noCache:
                return .onInteractionNoCache
            case .manualCache:
                return .manualCache
            }
        }
    }
    
    @IBAction func modeButonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a feature request mode.",
            message: nil,
            preferredStyle: .actionSheet
        )
        FeatureRequestMode.allCases.forEach { mode in
            let action = UIAlertAction(title: mode.title, style: .default) { [self] _ in
                changeFeatureRequestMode(to: mode.mode)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = modeBarButtonItem
        present(alertController, animated: true)
    }
    
    @IBAction func populateManualCache(_ button: UIBarButtonItem) {
        // set query parameters
        let params = AGSQueryParameters()
        // for specific request type
        params.whereClause = "Condition = '4'"
        
        // populate features based on query
        self.featureTable.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
            // check for error
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                // the resulting features should be displayed on the map
                // you can print the count of features
                print("Populated \(result?.featureEnumerator().allObjects.count ?? 0) features.")
            }
        }
    }
    
    private func changeFeatureRequestMode(to mode: AGSFeatureRequestMode) {
        if mode == .manualCache {
            populateBarButtonItem.isEnabled = true
        } else {
            populateBarButtonItem.isEnabled = false
        }
        let map = mapView.map
        map?.operationalLayers.removeAllObjects()
        featureTable.clearCache(withKeepLocalEdits: false)
        // set the request mode
        featureTable.featureRequestMode = mode
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // add the feature layer to the map
        map?.operationalLayers.add(featureLayer)
        
        mapView.map = map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureRequestModeViewController"]
    }
}
