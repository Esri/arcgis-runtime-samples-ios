// Copyright 2021 Esri
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

class DisplayContentUtilityNetworkContainerViewController: UIViewController, AGSGeoViewTouchDelegate, UIAdaptivePresentationControllerDelegate {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The bar button item to prompt return of the main view.
    @IBOutlet var exitBarButtonItem: UIBarButtonItem!
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    var utilityNetwork: AGSUtilityNetwork?
    /// The default or previous viewpoint before entering the container view.
    var previousViewpoint: AGSViewpoint?
    /// An array containing information about the feature services' legends.
    var legendInfos = [AGSLegendInfo]()
    
    // The symbols used to display the container view contents.
    let boundingBoxSymbol = AGSSimpleLineSymbol(style: .dash, color: .yellow, width: 3)
    let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .blue, width: 3)
    let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
    
    /// The action that is prompted when exiting the container view.
    @IBAction func exitContainerView() {
        // Disable the bar button item since container view will be exited.
        exitBarButtonItem.isEnabled = false
        // Remove all the objects that were added onto the graphics overlay.
        (mapView.graphicsOverlays[0] as? AGSGraphicsOverlay)?.graphics.removeAllObjects()
        (mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
            // Make each operational layer visible.
            layer.isVisible = true
            guard let previousViewpoint = previousViewpoint else { return }
            // Return to the viewpoint before container view was entered.
            mapView.setViewpointGeometry(previousViewpoint.targetGeometry) { [weak self] _ in
                // Enable interaction on the map view.
                self?.mapView.isUserInteractionEnabled = true
            }
        }
    }
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let webMapURL = URL(string: "https://ss7portal.arcgisonline.com/arcgis/home/item.html?id=5b64cf7a89ca4f98b5ed3da545d334ef")!
        let map = AGSMap(url: webMapURL)!
        return map
    }
    
    /// Create and load the utility network using the feature service URL.
    func loadUtilityNetwork() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: mapView.map!)
        utilityNetwork?.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Get the legend information provided by the feature layers used in the utility network.
    func getLegends() {
        // Create feature tables from URLs.
        let electricDistributionTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/105")!)
        let structureJunctionTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/900")!)
        // Create feature layers using the feature tables.
        let featureLayers = [electricDistributionTable, structureJunctionTable].map(AGSFeatureLayer.init)
        featureLayers.forEach { layer in
            // Get the legend information of each layer.
            layer.fetchLegendInfos { [weak self] (legendInfos, error) in
                guard let self = self, let legendInfos = legendInfos else { return }
                self.legendInfos.append(contentsOf: legendInfos)
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    /// Get the container feature that was tapped on.
    ///
    /// - Parameters:
    ///   - layerResults: The layer results identified by the touch delegate.
    ///   - completion: A closure to pass back the feature that was tapped on.
    func getContainerFeature(layerResults: [AGSIdentifyLayerResult], completion: @escaping (AGSArcGISFeature) -> Void) {
        // A map containing SubtypeFeatureLayer is expected to have features as part of its sublayer's result.
        layerResults.forEach { layerResult in
            if layerResult.layerContent is AGSSubtypeFeatureLayer {
                layerResult.sublayerResults.forEach { sublayerResult in
                    sublayerResult.geoElements.forEach { geoElement in
                        if let feature = geoElement as? AGSArcGISFeature {
                            completion(feature)
                        }
                    }
                }
            }
        }
    }
    
    func getAssociations(for containerFeature: AGSArcGISFeature) {
        guard let containerElement = utilityNetwork?.createElement(with: containerFeature) else { return }
        // Get the containment associations from this element to display its content.
        utilityNetwork?.associations(with: containerElement, type: .containment) { containmentAssociations, error in
            var contentElements = [AGSUtilityElement]()
            containmentAssociations?.forEach { association in
                var otherElement: AGSUtilityElement
                if association.fromElement.objectID == containerElement.objectID {
                    otherElement = association.toElement
                } else {
                    otherElement = association.fromElement
                }
                contentElements.append(otherElement)
            }
            if !contentElements.isEmpty {
                self.getFeatures(with: containerElement, for: contentElements)
            }
            if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    func getAssociationsWithExtent(boundingBox: AGSGeometry, overlay: AGSGraphicsOverlay) {
        overlay.graphics.add(AGSGraphic(geometry: boundingBox, symbol: boundingBoxSymbol))
        let geometry = AGSGeometryEngine.bufferGeometry(overlay.extent, byDistance: 0.05)!
        mapView.setViewpointGeometry(geometry) { _ in
            // Get the associations for this extent to display how content features are attached or connected.
            self.utilityNetwork?.associations(withExtent: overlay.extent) { (containmentAssociations, error) in
                containmentAssociations?.forEach { association in
                    var symbol = AGSSymbol()
                    if association.associationType == .attachment {
                        symbol = self.attachmentSymbol
                    } else {
                        symbol = self.connectivitySymbol
                    }
                    overlay.graphics.add(AGSGraphic(geometry: association.geometry, symbol: symbol))
                }
                self.exitBarButtonItem.isEnabled = true
                self.mapView.isUserInteractionEnabled = false
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    
    func getFeatures(with containerElement: AGSUtilityElement, for contentElements: [AGSUtilityElement]) {
        previousViewpoint = mapView.currentViewpoint(with: .boundingGeometry)
        (mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
            layer.isVisible = false
        }
        guard let overlay = mapView.graphicsOverlays.firstObject as? AGSGraphicsOverlay else { return }
        utilityNetwork?.features(for: contentElements) { (contentFeatures, error) in
            if let contentFeatures = contentFeatures {
                contentFeatures.forEach { content in
                    let symbol = (content.featureTable as? AGSArcGISFeatureTable)?.layerInfo?.drawingInfo?.renderer?.symbol(for: content)
                    overlay.graphics.add(AGSGraphic(geometry: content.geometry, symbol: symbol))
                }
                var boundingBox: AGSGeometry?
                if overlay.graphics.count == 1,
                   let point = (overlay.graphics.firstObject as? AGSGraphic)?.geometry as? AGSPoint {
                    self.mapView.setViewpointCenter(point, scale: containerElement.assetType.containerViewScale) { _ in
                        guard let boundingBox = self.mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry else { return }
                        self.getAssociationsWithExtent(boundingBox: boundingBox, overlay: overlay)
                    }
                } else {
                    boundingBox = AGSGeometryEngine.bufferGeometry(overlay.extent, byDistance: 0.05)
                    self.getAssociationsWithExtent(boundingBox: boundingBox!, overlay: overlay)
                }
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false) { [weak self] (layerResults, error) in
            guard let self = self else { return }
            if let layerResults = layerResults {
                self.getContainerFeature(layerResults: layerResults) { containerFeature in
                    self.getAssociations(for: containerFeature)
                }
//                self.getAssociations()
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the utility network.
        loadUtilityNetwork()
        // Add a graphics overlay.
        mapView.graphicsOverlays.add(AGSGraphicsOverlay())
        // Add self as the touch delegate for the map view.
        mapView.touchDelegate = self
        // Get the legends from the feature service.
        getLegends()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayContentUtilityNetworkContainer"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayContentLegendSegue" {
            let controller = segue.destination as! DisplayContentUtilityNetworkTableViewController
            controller.presentationController?.delegate = self
            // Set the size of the view controller.
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.legendInfos = legendInfos
            // Create a swatch of the bounding box symbol.
            boundingBoxSymbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
                if let image = image {
                    controller.boundingBoxSwatch = image.withRenderingMode(.alwaysOriginal)
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
            // Create a swatch of the attachment symbol.
            attachmentSymbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
                if let image = image {
                    controller.attachmentSwatch = image.withRenderingMode(.alwaysOriginal)
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
            // Create a swatch of the connectivity symbol.
            connectivitySymbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
                if let image = image {
                    controller.connectivitySwatch = image.withRenderingMode(.alwaysOriginal)
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
