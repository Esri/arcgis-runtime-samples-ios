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

class FeatureRequestModeViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISLightGrayBase)
            let extent = AGSEnvelope(
                xMin: -1.30758164047166E7,
                yMin: 4014771.46954516,
                xMax: -1.30730056797177E7,
                yMax: 4016869.78617381,
                spatialReference: .webMercator()
            )
            mapView.setViewpoint(AGSViewpoint(targetExtent: extent))
        }
    }
    @IBOutlet weak var featureRequestModeButton: UIBarButtonItem!
    
    private static let featureServiceURL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/PoolPermits/FeatureServer/0"
    private static let featureServiceSFURL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"
    let featureTable = AGSServiceFeatureTable(url: URL(string: featureServiceURL)!)
    let featureTableSF = AGSServiceFeatureTable(url: URL(string: featureServiceSFURL)!)
    
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
//        filterBarrierCategories.forEach { category in
//            let action = UIAlertAction(title: category.name, style: .default) { [self] _ in
//                selectedCategory = category
//                setStatus(message: "\(category.name) selected.")
//                traceResetBarButtonItem.isEnabled = true
//            }
//            alertController.addAction(action)
//        }
        FeatureRequestMode.allCases.forEach { mode in
            let action = UIAlertAction(title: mode.title, style: .default) { [self] _ in
                changeFeatureRequestMode(to: mode.mode)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = featureRequestModeButton
        present(alertController, animated: true)
    }
    
    private func changeFeatureRequestMode(to mode: AGSFeatureRequestMode) {
        let featureTable: AGSServiceFeatureTable
        if mode == .manualCache {
            featureTable = featureTableSF
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13630484, y: 4545415, spatialReference: .webMercator()), scale: 500000))
            populateManualCache()
        } else {
            featureTable = self.featureTable
            mapView.map = AGSMap(basemapStyle: .arcGISLightGrayBase)
            let extent = AGSEnvelope(
                xMin: -1.30758164047166E7,
                yMin: 4014771.46954516,
                xMax: -1.30730056797177E7,
                yMax: 4016869.78617381,
                spatialReference: .webMercator()
            )
            mapView.setViewpoint(AGSViewpoint(targetExtent: extent))
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
    
    func populateManualCache() {
        // set query parameters
        let params = AGSQueryParameters()
        // for specific request type
        params.whereClause = "req_Type = 'Tree Maintenance or Damage'"
        
        // populate features based on query
        self.featureTableSF.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureRequestModeViewController"]
    }
}
