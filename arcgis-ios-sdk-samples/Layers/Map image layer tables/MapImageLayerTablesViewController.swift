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
//

import UIKit
import ArcGIS

class MapImageLayerTablesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Assign the map to the MapView.
            mapView.map = makeMap()
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(latitude: 41.734152, longitude: -88.163718, scale: 2e5))
            // Create a graphics overlay to show selected features and add it to the map view.
            mapView.graphicsOverlays.add(selectedFeaturesOverlay)
        }
    }
    
    @IBOutlet var queryButton: UIBarButtonItem!
    
    @IBAction func queryFeaturesActions() {
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
                // Get the map image layer that contains the service request sublayer and the service request comments table.
                let serviceRequestsMapImageLayer = self.mapView.map?.operationalLayers.firstObject as? AGSArcGISMapImageLayer
                // Get the (non-spatial) table that contains the service request comments.
                guard let commentsTable = serviceRequestsMapImageLayer?.tables.first else { return }
                // Get the relationship that defines related service request features for features in the comments table (this is the first and only relationship).
                let commentsRelationshipInfo = commentsTable.layerInfo?.relationshipInfos.first
                // Create query parameters to get the related service request for features in the comments table.
                let relatedQueryParameters = AGSRelatedQueryParameters(relationshipInfo: commentsRelationshipInfo!)
                relatedQueryParameters.returnGeometry = true
                self.queryCommentsTable(feature: feature, commentsTable: commentsTable, relatedQueryParameters: relatedQueryParameters)
            }
            // Add the action to the controller.
            alertController.addAction(action)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        // Present the controller.
        alertController.popoverPresentationController?.barButtonItem = queryButton
        present(alertController, animated: true)
    }
    
    /// The service request URL.
    static let serviceRequestURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/ServiceRequest/MapServer")!
    /// The map image layer that uses the service URL.
    let serviceRequestsMapImageLayer = AGSArcGISMapImageLayer(url: serviceRequestURL)
    /// The array to store the possible comments.
    var commentsArray = [AGSFeature]()
    /// The graphics overlay to add graphics to.
    let selectedFeaturesOverlay = AGSGraphicsOverlay()
    
    func makeMap() -> AGSMap {
        // Create a map with the ArcGIS streets basemap style.
        let map = AGSMap(basemapStyle: .arcGISStreets)
        // Load the map image layer's tables and layers.
        serviceRequestsMapImageLayer.loadTablesAndLayers { _ in
            // Add the layer to the map.
            map.operationalLayers.add(self.serviceRequestsMapImageLayer)
            self.queryFeatures()
        }
        return map
    }
    
    /// Query features on the first table in the map image layer.
    func queryFeatures() {
        // Create query parameters and set its where clafisuse.
        let nullCommentsParameters = AGSQueryParameters()
        nullCommentsParameters.whereClause = "requestid <> '' AND comments <> ''"
        // Get the first table from the map image layer.
        guard let commentsTable = serviceRequestsMapImageLayer.tables.first else { return }
        // Query features on the feature table with the query parameters and all feature fields.
        commentsTable.queryFeatures(with: nullCommentsParameters, queryFeatureFields: .loadAll) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Show the records from the service request comments table in the list view control.
                self.commentsArray = (result?.featureEnumerator().allObjects)!
                // Enable the button after the map and features have been loaded.
                self.queryButton.isEnabled = true
            }
        }
    }
    
    /// Query related features for the selected feature.
    func queryCommentsTable(feature: AGSFeature, commentsTable: AGSServiceFeatureTable, relatedQueryParameters: AGSRelatedQueryParameters) {
        // Get the feature as an ArcGIS feature.
        guard let selectedComment = feature as? AGSArcGISFeature else { return }
        // Query related features for the selected comment and its related query parameters.
        commentsTable.queryRelatedFeatures(for: selectedComment, parameters: relatedQueryParameters) { results, error in
            let relatedResult = results?.first
            // Get the first related feature.
            if let relatedFeature = relatedResult?.featureEnumerator().nextObject() as? AGSArcGISFeature {
                // Load the feature and get its geometry to show as a graphic on the map.
                relatedFeature.load { error in
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        // Get the feature's geometry.
                        guard let serviceRequestPoint = relatedFeature.geometry as? AGSPoint else { return }
                        // Create a symbol for the feature.
                        let selectedRequestSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .cyan, size: 14)
                        // Create a graphic with the geometry and symbol.
                        let requestGraphic = AGSGraphic(geometry: serviceRequestPoint, symbol: selectedRequestSymbol)
                        // Add the graphic to the graphics overlay.
                        self.selectedFeaturesOverlay.graphics.add(requestGraphic)
                        // Set the viewpoint to the the related feature.
                        self.mapView.setViewpointCenter(serviceRequestPoint, scale: 150_000)
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
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [ "MapImageLayerTablesViewController"]
    }
}
