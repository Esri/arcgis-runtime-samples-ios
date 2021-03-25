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
    @IBOutlet var legendBarButtonItem: UIBarButtonItem!
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    var utilityNetwork: AGSUtilityNetwork?
    let graphicsOverlay = AGSGraphicsOverlay()
    /// The default or previous viewpoint before entering the container view.
    var previousViewpoint: AGSViewpoint?
    /// An array containing information about the feature services' legends.
    var legendInfos = [AGSLegendInfo]()
    var featureLayers = [AGSFeatureLayer]()
    
    // The symbols used to display the container view contents.
    let boundingBoxSymbol = AGSSimpleLineSymbol(style: .dash, color: .yellow, width: 3)
    let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .green, width: 3)
    let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
    
    /// The action that is prompted when exiting the container view.
    @IBAction func exitContainerView() {
        // Disable the bar button item since container view will be exited.
        exitBarButtonItem.isEnabled = false
        // Remove all the objects that were added onto the graphics overlay.
        graphicsOverlay.graphics.removeAllObjects()
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
            // Add self as the touch delegate for the map view.
            self?.mapView.touchDelegate = self
            if let error = error {
                self?.presentAlert(error: error)
            }
        }
    }
    
    /// Get the legend information provided by the feature layers used in the utility network.
    func fetchLegendInfo() {
        // Create feature tables from URLs.
        let electricDistributionTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("105"))
        let structureJunctionTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("900"))
        // Create feature layers using the feature tables.
        featureLayers = [electricDistributionTable, structureJunctionTable].map(AGSFeatureLayer.init)
        featureLayers.forEach { layer in
            // Get the legend information of each layer.
            layer.fetchLegendInfos { [weak self] (legendInfos, error) in
                guard let self = self, let legendInfos = legendInfos else { return }
                self.legendBarButtonItem.isEnabled = true
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
    func identifyContainerFeature(layerResults: [AGSIdentifyLayerResult], completion: @escaping (AGSArcGISFeature) -> Void) {
        // A map containing SubtypeFeatureLayer is expected to have features as part of its sublayer's result.
        let layerResult = layerResults.first(where: { $0.layerContent is AGSSubtypeFeatureLayer })
        layerResult?.sublayerResults.forEach { sublayerResult in
            guard let feature = sublayerResult.geoElements.first(where: { $0 is AGSArcGISFeature }) as? AGSArcGISFeature else { return }
            completion(feature)
        }
    }
    
    /// Get the containment associations from the chosen element.
    ///
    /// - Parameter containerFeature: The selected container feature
    func addElementAssociations(for containerFeature: AGSArcGISFeature) {
        // Create a container element using the selected feature.
        guard let containerElement = utilityNetwork?.createElement(with: containerFeature) else { return }
        // Get the containment associations from this element to display its content.
        utilityNetwork?.associations(with: containerElement, type: .containment) { [weak self] containmentAssociations, error in
            guard let self = self else { return }
            var contentElements = [AGSUtilityElement]()
            // Determine the type of each element and add it to the array of content elements.
            containmentAssociations?.forEach { association in
                var element: AGSUtilityElement
                if association.fromElement.objectID == containerElement.objectID {
                    element = association.toElement
                } else {
                    element = association.fromElement
                }
                contentElements.append(element)
            }
            // If there are elements, find their corresponding features.
            if !contentElements.isEmpty {
                self.addGraphicsToFeatures(within: containerElement, for: contentElements)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Get the features that correspond to the content's elements and add graphics.
    ///
    /// - Parameters:
    ///     - containerElement: The container element of the selected feature
    ///     - contentElements: An array of the content elements.
    func addGraphicsToFeatures(within containerElement: AGSUtilityElement, for contentElements: [AGSUtilityElement]) {
        // Save the previous viewpoint.
        previousViewpoint = mapView.currentViewpoint(with: .boundingGeometry)
        // Hide the layers to display the container view.
        (mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
            layer.isVisible = false
        }
        // Get the corresponding features for the array of content elements.
        utilityNetwork?.features(for: contentElements) { [weak self] (contentFeatures, error) in
            guard let self = self else { return }
            if let contentFeatures = contentFeatures {
                if contentFeatures.count == 1 {
                    self.presentAlert(title: nil, message: "This feature contains no associations.")
                }
                // Create and add a symbol for each of the features.
                contentFeatures.forEach { content in
                    let symbol = (content.featureTable as? AGSArcGISFeatureTable)?.layerInfo?.drawingInfo?.renderer?.symbol(for: content)
                    self.graphicsOverlay.graphics.add(AGSGraphic(geometry: content.geometry, symbol: symbol))
                }
                // The bounding box which defines the container view may be computed using the extent of the features it contains or centered around its geometry at the container's view scale.
                var boundingBox: AGSGeometry?
                if self.graphicsOverlay.graphics.count == 1,
                   let point = (self.graphicsOverlay.graphics.firstObject as? AGSGraphic)?.geometry as? AGSPoint {
                    self.mapView.setViewpointCenter(point, scale: containerElement.assetType.containerViewScale) { _ in
                        guard let boundingBox = self.mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry else { return }
                        self.identifyAssociationsWithExtent(boundingBox: boundingBox)
                    }
                } else {
                    boundingBox = AGSGeometryEngine.bufferGeometry(self.graphicsOverlay.extent, byDistance: 0.05)
                    self.identifyAssociationsWithExtent(boundingBox: boundingBox!)
                }
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Get associations for the specified extent and display its associations.
    ///
    /// - Parameter boundingBox: The gemeotry which represents the boundaries of the extent.
    func identifyAssociationsWithExtent(boundingBox: AGSGeometry) {
        // Add the bounding box symbol.
        graphicsOverlay.graphics.add(AGSGraphic(geometry: boundingBox, symbol: boundingBoxSymbol))
        let geometry = AGSGeometryEngine.bufferGeometry(graphicsOverlay.extent, byDistance: 0.05)!
        mapView.setViewpointGeometry(geometry) { [weak self] _ in
            guard let self = self else { return }
            // Get the associations for this extent to display how content features are attached or connected.
            self.utilityNetwork?.associations(withExtent: self.graphicsOverlay.extent) { (containmentAssociations, error) in
                guard let containmentAssociations = containmentAssociations else { return }
                containmentAssociations.forEach { association in
                    var symbol = AGSSymbol()
                    if association.associationType == .attachment {
                        symbol = self.attachmentSymbol
                    } else {
                        symbol = self.connectivitySymbol
                    }
                    self.graphicsOverlay.graphics.add(AGSGraphic(geometry: association.geometry, symbol: symbol))
                }
                // Enable the bar button item to exit the container view.
                self.exitBarButtonItem.isEnabled = true
                // Turn off user interaction to avoid straying away from the container view.
                self.mapView.isUserInteractionEnabled = false
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Identify the top most feature that corresponds to the tapped point.
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false) { [weak self] (layerResults, error) in
            guard let self = self else { return }
            if let layerResults = layerResults {
                self.identifyContainerFeature(layerResults: layerResults) { containerFeature in
                    self.addElementAssociations(for: containerFeature)
                }
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Create a swatch from the provided symbol.
    ///
    /// - Parameter symbol: The symbol to make a swatch from.
    /// - Returns The resulting image that represents the swatch.
    func makeSwatch(symbol: AGSSymbol) -> UIImage {
        let swatchGroup = DispatchGroup()
        var swatchImage = UIImage()
        swatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            symbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
                if let image = image {
                    swatchImage = image
                } else if let error = error {
                    self?.presentAlert(error: error)
                }
                swatchGroup.leave()
            }
        }
        swatchGroup.wait()
        return swatchImage
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the utility network.
        loadUtilityNetwork()
        // Add a graphics overlay.
        mapView.graphicsOverlays.add(graphicsOverlay)
        mapView.setViewpoint(AGSViewpoint(latitude: 41.801504, longitude: -88.163718, scale: 4e3))
        // Get the legends from the feature service.
        fetchLegendInfo()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayContentUtilityNetworkContainerViewController", "DisplayContentUtilityNetworkTableViewController"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayContentLegendSegue" {
            let controller = segue.destination as! DisplayContentUtilityNetworkTableViewController
            controller.presentationController?.delegate = self
            controller.legendInfos = legendInfos
            controller.contentSwatches = [
                "Bounding box": makeSwatch(symbol: boundingBoxSymbol),
                "Attachment": makeSwatch(symbol: attachmentSymbol),
                "Connectivity": makeSwatch(symbol: connectivitySymbol)
            ]
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
