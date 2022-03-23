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
            mapView.map = makeMap()
            // Assign the map to the MapView.
            mapView.graphicsOverlays.add(selectedFeaturesOverlay)
        }
    }
    
    @IBOutlet var queryButton: UIBarButtonItem!
    
    @IBAction func queryFeaturesActions() {
        selectedFeaturesOverlay.graphics.removeAllObjects()
        let alertController = UIAlertController(title: "Related Service Requests", message: "Select a comment to view related spatial features on the map.", preferredStyle: .actionSheet)
        itemsSource.forEach { feature in
            let commentsTitle = feature.attributes["comments"] as! String
            let action = UIAlertAction(title: commentsTitle, style: .default) { (_) in
                // Get the map image layer that contains the service request sublayer and the service request comments table.
                let serviceRequestsMapImageLayer = self.mapView.map?.operationalLayers.firstObject as? AGSArcGISMapImageLayer
                // Get the (non-spatial) table that contains the service request comments.
                let commentsTable = serviceRequestsMapImageLayer?.tables.first
                // Get the relationship that defines related service request features for features in the comments table (this is the first and only relationship).
                let commentsRelationshipInfo = commentsTable?.layerInfo?.relationshipInfos.first
                // Create query parameters to get the related service request for features in the comments table.
                self.relatedQueryParameters = AGSRelatedQueryParameters(relationshipInfo: commentsRelationshipInfo!)
                self.relatedQueryParameters?.returnGeometry = true
                self.queryCommentsTable(feature: feature, commentsTable: commentsTable!)
            }
            alertController.addAction(action)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = queryButton
        present(alertController, animated: true)
    }
    
    static let serviceRequestURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/ServiceRequest/MapServer")!
    let serviceRequestsMapImageLayer = AGSArcGISMapImageLayer(url: serviceRequestURL)
    var itemsSource = [AGSFeature]()
    var relatedQueryParameters: AGSRelatedQueryParameters?
    let selectedFeaturesOverlay = AGSGraphicsOverlay()
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISStreets)
        serviceRequestsMapImageLayer.loadTablesAndLayers { _ in
            let requestsExtent = self.serviceRequestsMapImageLayer.fullExtent!
            map.initialViewpoint = AGSViewpoint(targetExtent: requestsExtent)
            map.operationalLayers.add(self.serviceRequestsMapImageLayer)
            self.queryFeatures()
        }
        return map
    }
    
    func queryFeatures() {
        let commentsTable = serviceRequestsMapImageLayer.tables.first
        let nullCommentsParameters = AGSQueryParameters()
        nullCommentsParameters.whereClause = "requestid <> '' AND comments <> ''"
        
        commentsTable?.queryFeatures(with: nullCommentsParameters, queryFeatureFields: .loadAll) { result, error in
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Show the records from the service request comments table in the list view control.
                self.itemsSource = (result?.featureEnumerator().allObjects)!
                self.queryButton.isEnabled = true
                // Create a graphics overlay to show selected features and add it to the map view.
            }
        }
    }
    
    func queryCommentsTable(feature: AGSFeature, commentsTable: AGSServiceFeatureTable) {
        let selectedComment = feature as! AGSArcGISFeature
        commentsTable.queryRelatedFeatures(for: selectedComment, parameters: relatedQueryParameters!) { results, error in
            let relatedResult = results?.first
            if let relatedFeature = relatedResult?.featureEnumerator().nextObject() as? AGSArcGISFeature {
                relatedFeature.load { error in
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        let serviceRequestPoint = relatedFeature.geometry as? AGSPoint
                        let selectedRequestSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .cyan, size: 14)
                        let requestGraphic = AGSGraphic(geometry: serviceRequestPoint, symbol: selectedRequestSymbol)
                        self.selectedFeaturesOverlay.graphics.add(requestGraphic)
                        self.mapView.setViewpointCenter(serviceRequestPoint!, scale: 150_000)
                    }
                }
            } else {
                self.presentAlert(title: "Related feature not found. No Feature", message: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [ "MapImageLayerTablesViewController"]
    }
}
