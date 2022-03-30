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

class QueryRelatedFeaturesNonSpatialTable: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Assign the map to the map view.
            mapView.map = makeMap()
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(latitude: 41.734152, longitude: -88.163718, scale: 2e5))
            // Add a graphics overlay to show selected features and add it to the map view.
            selectedFeaturesOverlay.renderer = makeRenderer()
            mapView.graphicsOverlays.add(selectedFeaturesOverlay)
        }
    }
    
    @IBOutlet var queryBarButtonItem: UIBarButtonItem!
    
    /// The service request URL.
    static let serviceRequestURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/ServiceRequest/MapServer")!
    /// The map image layer that uses the service URL.
    let serviceRequestsMapImageLayer = AGSArcGISMapImageLayer(url: serviceRequestURL)
    /// The (non-spatial) table that contains the service request comments.
    var commentsTable: AGSServiceFeatureTable?
    /// The array to store the possible comments.
    var commentsArray: [AGSFeature] = []
    /// The graphics overlay to add graphics to.
    let selectedFeaturesOverlay = AGSGraphicsOverlay()
    
    @IBAction func queryFeaturesActions(_ sender: UIBarButtonItem) {
        // Create an action sheet to display the various comments to choose from.
        let alertController = UIAlertController(title: "Related Service Requests", message: "Select a comment to view related spatial features on the map.", preferredStyle: .actionSheet)
        // Create an action for each comment.
        commentsArray.forEach { feature in
            // Extract the "comments" attribute as a string.
            let commentsTitle = feature.attributes["comments"] as! String
            // Create an action with the comments title.
            let action = UIAlertAction(title: commentsTitle, style: .default) { [weak self] (_) in
                guard let self = self else { return }
                // Clear the former graphics.
                self.selectedFeaturesOverlay.graphics.removeAllObjects()
                // Disable the query button while the feature loads.
                self.queryBarButtonItem.isEnabled = false
                // Cast the selected feature as an AGSArcGISFeature.
                guard let selectedFeature = feature as? AGSArcGISFeature else { return }
                self.queryCommentsTable(feature: selectedFeature)
            }
            // Add the action to the controller.
            alertController.addAction(action)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        // Present the controller.
        alertController.popoverPresentationController?.barButtonItem = queryBarButtonItem
        present(alertController, animated: true)
    }
    
    /// Make a map for the map view.
    func makeMap() -> AGSMap {
        // Create a map with the ArcGIS streets basemap style.
        let map = AGSMap(basemapStyle: .arcGISStreets)
        // Add the layer to the map.
        map.operationalLayers.add(serviceRequestsMapImageLayer)
        // Load the map image layer's tables and layers.
        serviceRequestsMapImageLayer.loadTablesAndLayers { [weak self] _ in
            self?.queryFeatures()
        }
        return map
    }
    
    /// Make a renderer for the graphics overlay.
    func makeRenderer () -> AGSSimpleRenderer {
        let renderer = AGSSimpleRenderer()
        // Create a symbol for the feature.
        let selectedRequestSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .cyan, size: 14)
        // Set the renderer's symbol.
        renderer.symbol = selectedRequestSymbol
        return renderer
    }
    
    /// Query features on the first table in the map image layer.
    func queryFeatures() {
        // Create query parameters and set its where clause.
        let nullCommentsParameters = AGSQueryParameters()
        nullCommentsParameters.whereClause = "requestid <> '' AND comments <> ''"
        // Set the first table from the map image layer.
        commentsTable = serviceRequestsMapImageLayer.tables.first
        // Query features on the feature table with the query parameters and all feature fields.
        commentsTable?.queryFeatures(with: nullCommentsParameters, queryFeatureFields: .loadAll) { [weak self] result, error in
            guard let self = self else { return }
            if let comments = result?.featureEnumerator().allObjects {
                // Show the records from the service request comments table in the list view control.
                self.commentsArray = comments
                // Enable the button after the map and features have been loaded.
                self.queryBarButtonItem.isEnabled = true
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Query related features for the selected feature.
    func queryCommentsTable(feature: AGSArcGISFeature) {
        // Get the relationship that defines related service request features for features in the comments table (this is the first and only relationship).
        guard let commentsRelationshipInfo = commentsTable?.layerInfo?.relationshipInfos.first else { return }
        // Create query parameters to get the related service request for features in the comments table.
        let relatedQueryParameters = AGSRelatedQueryParameters(relationshipInfo: commentsRelationshipInfo)
        relatedQueryParameters.returnGeometry = true
        // Query related features for the selected comment and its related query parameters.
        commentsTable?.queryRelatedFeatures(for: feature, parameters: relatedQueryParameters) { results, error in
            // Get the first related feature.
            if let relatedFeature = results?.first?.featureEnumerator().nextObject() as? AGSArcGISFeature {
                // Load the feature and get its geometry to show as a graphic on the map.
                relatedFeature.load { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        // Get the feature's geometry.
                        guard let serviceRequestPoint = relatedFeature.geometry as? AGSPoint else { return }
                        // Create a graphic to add to the graphics overlay.
                        let graphic = AGSGraphic(geometry: serviceRequestPoint, symbol: nil)
                        self.selectedFeaturesOverlay.graphics.add(graphic)
                        // Set the viewpoint to the the related feature.
                        self.mapView.setViewpointCenter(serviceRequestPoint, scale: 150_000)
                        // Enable the button after the feature has finished loading.
                        self.queryBarButtonItem.isEnabled = true
                    }
                }
            } else {
                // Present an error message is the related feature is not found.
                self.presentAlert(title: "Related feature not found. No Feature", message: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["QueryRelatedFeaturesNonSpatialTable"]
    }
}
