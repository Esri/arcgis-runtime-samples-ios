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

class QueryWithCQLFiltersViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let map = AGSMap(basemapStyle: .arcGISTopographic)
            map.operationalLayers.add(ogcFeatureLayer)
            mapView.map = map
            // Set the viewpoint to Daraa, Syria.
            mapView.setViewpoint(AGSViewpoint(latitude: 32.62, longitude: 36.10, scale: 20_000))
        }
    }
    /// The button to present the CQL filters settings.
    @IBOutlet var cqlFiltersBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// The most recent query job.
    var lastQuery: AGSCancelable?
    
    /// A feature layer to visualize the OGC API features.
    let ogcFeatureLayer: AGSFeatureLayer = {
        // Note: the collection ID can be accessed later via
        // `featureCollectionInfo.collectionID` property of the feature table.
        let table = AGSOGCFeatureCollectionTable(
            url: URL(string: "https://demo.ldproxy.net/daraa")!,
            collectionID: "TransportationGroundCrv"
        )
        // Set the feature request mode to manual (only manual is currently
        // supported). In this mode, you must manually populate the table -
        // panning and zooming won't request features automatically.
        table.featureRequestMode = .manualCache
        
        let featureLayer = AGSFeatureLayer(featureTable: table)
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 3)
        featureLayer.renderer = AGSSimpleRenderer(symbol: lineSymbol)
        return featureLayer
    }()
    
    // MARK: Method
    
    func populateFeaturesFromQuery(queryParameters: AGSQueryParameters) {
        // Cancel if there is an existing query request.
        lastQuery?.cancel()
        
        // Populate the table with the query. Setting `outFields` to `nil`
        // requests all fields.
        let table = ogcFeatureLayer.featureTable as! AGSOGCFeatureCollectionTable
        lastQuery = table.populateFromService(
            with: queryParameters,
            clearCache: true,
            outfields: nil
        ) { [weak self] result, error in
            guard let self = self else { return }
            self.lastQuery = nil
            if let error = error,
               // Do not display error if user cancelled the request.
               (error as NSError).code != NSUserCancelledError {
                self.presentAlert(error: error)
            } else if let result = result, let extent = self.ogcFeatureLayer.featureTable?.extent {
                // Zoom to the extent of the selected collection.
                self.mapView.setViewpointGeometry(extent, padding: 50)
                self.presentAlert(title: "Query Result", message: "Query returned \(result.featureEnumerator().allObjects.count) features.")
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "QueryWithCQLFiltersViewController",
            "QueryWithCQLFiltersSettingsViewController"
        ]
        ogcFeatureLayer.load { [weak self] error in
            guard error == nil else { return }
            self?.cqlFiltersBarButtonItem.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
           let controller = navigationController.topViewController as? QueryWithCQLFiltersSettingsViewController {
            controller.delegate = self
        }
    }
}

// MARK: - QueryWithCQLFiltersSettingsViewControllerDelegate

extension QueryWithCQLFiltersViewController: QueryWithCQLFiltersSettingsViewControllerDelegate {
    func settingsViewController(_ controller: QueryWithCQLFiltersSettingsViewController, queryParameters: AGSQueryParameters) {
        populateFeaturesFromQuery(queryParameters: queryParameters)
    }
}
