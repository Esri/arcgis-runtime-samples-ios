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

class EditFeatureAttachmentsViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISOceans)
            // Set touch delegate on map view as self.
            mapView.touchDelegate = self
            mapView.callout.delegate = self
        }
    }
    
    /// The feature table to update features geometries.
    var featureTable: AGSServiceFeatureTable!
    /// The service geodatabase that contains damaged property features.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// The feature layer created from the feature table.
    var featureLayer: AGSFeatureLayer!
    /// Last identify operation.
    var lastQuery: AGSCancelable!
    /// The currently selected feature.
    var selectedFeature: AGSArcGISFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "EditFeatureAttachmentsViewController",
            "AttachmentsTableViewController"
        ]
        
        // Load the service geodatabase.
        let damageFeatureService = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer")!
        loadServiceGeodatabase(from: damageFeatureService)
    }
    
    /// Load and set a service geodatabase from a feature service URL.
    /// - Parameter serviceURL: The URL to the feature service.
    func loadServiceGeodatabase(from serviceURL: URL) {
        let serviceGeodatabase = AGSServiceGeodatabase(url: serviceURL)
        serviceGeodatabase.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                let featureTable = serviceGeodatabase.table(withLayerID: 0)!
                self.featureTable = featureTable
                self.serviceGeodatabase = serviceGeodatabase
                // Add the feature layer to the operational layers on map.
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                self.featureLayer = featureLayer
                self.mapView.map?.operationalLayers.add(featureLayer)
                self.mapView.setViewpoint(AGSViewpoint(
                    center: AGSPoint(x: 0, y: 0, spatialReference: .webMercator()),
                    scale: 1e8
                ))
            }
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
           let controller = navController.viewControllers.first as? AttachmentsTableViewController {
            controller.feature = selectedFeature
            controller.serviceGeodatabase = serviceGeodatabase
            controller.isModalInPresentation = true
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension EditFeatureAttachmentsViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let query = lastQuery { query.cancel() }
        // Hide the callout.
        mapView.callout.dismiss()
        
        lastQuery = mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) in
            guard let self = self else { return }
            self.lastQuery = nil
            if let feature = identifyLayerResult.geoElements.first as? AGSArcGISFeature {
                // fetch attachment
                feature.fetchAttachments { (attachments: [AGSAttachment]?, error: Error?) in
                    if let error = error {
                        print(error)
                    } else if let attachments = attachments {
                        // Show callout for the feature.
                        let title = feature.attributes["typdamage"] as! String
                        let detail = "Number of attachments: \(attachments.count)"
                        self.mapView.callout.title = title
                        self.mapView.callout.detail = detail
                        self.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
                        // Update selected feature.
                        self.selectedFeature = feature
                    }
                }
            } else if let error = identifyLayerResult.error {
                self.presentAlert(error: error)
            }
        }
    }
}

// MARK: - AGSCalloutDelegate

extension EditFeatureAttachmentsViewController: AGSCalloutDelegate {
    func didTapAccessoryButton(for callout: AGSCallout) {
        // Hide the callout.
        mapView.callout.dismiss()
        // Show the attachments list view controller.
        performSegue(withIdentifier: "AttachmentsSegue", sender: self)
    }
}
