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
            AGSAuthenticationManager.shared().delegate = self
            makeMap()
            mapView.setViewpoint(AGSViewpoint(latitude: 41.801504, longitude: -88.163718, scale: 4e3))
        }
    }
    /// The bar button item to prompt return of the main view.
    @IBOutlet var exitBarButtonItem: UIBarButtonItem!
    @IBOutlet var legendBarButtonItem: UIBarButtonItem!
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    var utilityNetwork: AGSUtilityNetwork?
    let graphicsOverlay = AGSGraphicsOverlay()
    /// The default or previous viewpoint before entering the container view.
    var previousViewpoint: AGSViewpoint?
    /// An array containing information about the feature services' legends.
    var legendInfos = [AGSLegendInfo]()
    var featureLayers = [AGSFeatureLayer]()
    
    // The symbols used to display the container view contents.
    let boundingBoxSymbol = ContainerViewSymbol(
        name: "Bounding box",
        symbol: AGSSimpleLineSymbol(style: .dash, color: .yellow, width: 3)
    )
    let attachmentSymbol = ContainerViewSymbol(
        name: "Attachment",
        symbol: AGSSimpleLineSymbol(style: .dot, color: .green, width: 3)
    )
    let connectivitySymbol = ContainerViewSymbol(
        name: "Connectivity",
        symbol: AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
    )
    
    /// The data source for the legend table.
        private var symbolsDataSource: SymbolsDataSource? {
            didSet {
                legendBarButtonItem.isEnabled = true
            }
        }
    
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
    func makeMap() {
        let webMapURL = URL(string: "https://sampleserver7.arcgisonline.com/portal/home/item.html?id=813eda749a9444e4a9d833a4db19e1c8")!
        let map = AGSMap(url: webMapURL)
        mapView.map = map
    }
    
    /// Create and load the utility network using the feature service URL.
    func loadUtilityNetwork() {
        guard let map = mapView.map else { return }
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: map)
        utilityNetwork?.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                // Add self as the touch delegate for the map view.
                self?.mapView.touchDelegate = self
            }
        }
    }
    
    /// Get the legend information provided by the feature layers used in the utility network.
    func fetchLegendInfo() {
        // Create feature tables from URLs.
        let electricDistributionTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("1"))
        let structureJunctionTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("5"))
        let legendGroup = DispatchGroup()
        // Create feature layers using the feature tables.
        featureLayers = [electricDistributionTable, structureJunctionTable].map(AGSFeatureLayer.init)
        featureLayers.forEach { layer in
            legendGroup.enter()
            // Get the legend information of each layer.
            layer.fetchLegendInfos { [weak self] (legendInfos, error) in
                guard let self = self, let legendInfos = legendInfos else { return }
                defer { legendGroup.leave() }
//                self.legendBarButtonItem.isEnabled = true
                self.legendInfos.append(contentsOf: legendInfos)
//                self.makeSwatches(legend: legendInfos) { legendItems in
//                    self.legendItems.append(contentsOf: legendItems)
//                    self.symbolsDataSource = SymbolsDataSource(legendItems: self.legendItems)
//                }
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
        legendGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let symbols = self.legendInfos + [self.boundingBoxSymbol, self.attachmentSymbol, self.connectivitySymbol]
            self.makeSwatches(legend: symbols) { legendItems in
                self.symbolsDataSource = SymbolsDataSource(legendItems: legendItems)
            }
        }
    }
    
    private func makeSwatches(legend: [Any], completion: @escaping ([LegendItem]) -> Void) {
        let swatchGroup = DispatchGroup()
        var legendItems = [LegendItem]()
        var symbol = AGSSymbol()
        var name = String()
        legend.forEach { symbolItem in
            if let legendInfoItem = symbolItem as? AGSLegendInfo, !legendInfoItem.name.isEmpty {
                name = legendInfoItem.name
                symbol = legendInfoItem.symbol!
            } else if let containerViewSymbol = symbolItem as? ContainerViewSymbol {
                name = containerViewSymbol.name
                symbol = containerViewSymbol.symbol
            }
            swatchGroup.enter()
            symbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
                if let image = image {
                    defer { swatchGroup.leave() }
                    legendItems.append(LegendItem(name: name, image: image))
                } else {
                    swatchGroup.leave()
                }
            }
        }
        swatchGroup.notify(queue: .main) {
            completion(legendItems)
        }
    }

    func makeSwatch(name: String, symbol: AGSSymbol) ->
    
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
        utilityNetwork?.associations(with: containerElement, type: .containment) { [weak self] containmentAssociations, _ in
            // Determine the type of each element and add it to the array of content elements.
            guard let self = self, let associations = containmentAssociations else { return }
            let contentElements: [AGSUtilityElement] = associations.map { association in
                if association.fromElement.objectID == containerElement.objectID {
                    return association.toElement
                } else {
                    return association.fromElement
                }
            }
            // If there are elements, find their corresponding features.
            if !contentElements.isEmpty {
                self.addGraphicsToFeatures(within: containerElement, for: contentElements)
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
                // Create and add a symbol for each of the features.
                contentFeatures.forEach { content in
                    let symbol = (content.featureTable as? AGSArcGISFeatureTable)?.layerInfo?.drawingInfo?.renderer?.symbol(for: content)
                    self.graphicsOverlay.graphics.add(AGSGraphic(geometry: content.geometry, symbol: symbol))
                }
                // The bounding box which defines the container view may be computed using the extent of the features it contains or centered around its geometry at the container's view scale.
                var boundingBox: AGSGeometry?
                if contentFeatures.count == 1,
                   let point = (self.graphicsOverlay.graphics.firstObject as? AGSGraphic)?.geometry as? AGSPoint {
                    self.mapView.setViewpointCenter(point, scale: containerElement.assetType.containerViewScale) { _ in
                        self.presentAlert(title: nil, message: "This feature contains no associations.")
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
        graphicsOverlay.graphics.add(AGSGraphic(geometry: boundingBox, symbol: boundingBoxSymbol.symbol))
        let geometry = AGSGeometryEngine.bufferGeometry(graphicsOverlay.extent, byDistance: 0.05)!
        mapView.setViewpointGeometry(geometry) { [weak self] _ in
            guard let self = self else { return }
            // Get the associations for this extent to display how content features are attached or connected.
            self.utilityNetwork?.associations(withExtent: self.graphicsOverlay.extent) { (containmentAssociations, error) in
                guard let containmentAssociations = containmentAssociations else { return }
                containmentAssociations.forEach { association in
                    var symbol = AGSSymbol()
                    if association.associationType == .attachment {
                        symbol = self.attachmentSymbol.symbol
                    } else {
                        symbol = self.connectivitySymbol.symbol
                    }
                    self.graphicsOverlay.graphics.add(AGSGraphic(geometry: association.geometry, symbol: symbol))
                }
                // Enable the bar button item to exit the container view.
                self.exitBarButtonItem.isEnabled = true
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Turn off user interaction to avoid straying away from the container view.
        self.mapView.isUserInteractionEnabled = false
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
//    func makeSwatch(symbol: AGSSymbol) -> UIImage {
//        let swatchGroup = DispatchGroup()
//        var swatchImage = UIImage()
//        swatchGroup.enter()
//        DispatchQueue.global(qos: .userInitiated).async {
//            symbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
//                if let image = image {
//                    swatchImage = image
//                } else if let error = error {
//                    self?.presentAlert(error: error)
//                }
//                swatchGroup.leave()
//            }
//        }
//        swatchGroup.wait()
//        return swatchImage
//    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the utility network.
        loadUtilityNetwork()
        // Add a graphics overlay.
        mapView.graphicsOverlays.add(graphicsOverlay)
        // Get the legends from the feature service.
        fetchLegendInfo()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayContentUtilityNetworkContainerViewController", "DisplayContentUtilityNetworkTableViewController"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayContentLegendSegue",
            let controller = segue.destination as? UITableViewController {
                controller.presentationController?.delegate = self
                controller.tableView.dataSource = symbolsDataSource
            }
//            as! DisplayContentUtilityNetworkTableViewController
//            controller.presentationController?.delegate = self
//            controller.legendInfos = legendInfos
//            controller.contentSwatches = [
//                "Bounding box": makeSwatch(symbol: boundingBoxSymbol),
//                "Attachment": makeSwatch(symbol: attachmentSymbol),
//                "Connectivity": makeSwatch(symbol: connectivitySymbol)
//            ]
//            controller.images = images
//        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension DisplayContentUtilityNetworkContainerViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        let credentials = AGSCredential(user: "editor01", password: "S7#i2LWmYH75")
        challenge.continue(with: credentials)
    }
}

// MARK: - SymbolsDataSource, UITableViewDataSource
private class SymbolsDataSource: NSObject, UITableViewDataSource {
    /// The legend items for the legend table.
    private let legendItems: [LegendItem]

    init(legendItems: [LegendItem]) {
        self.legendItems = legendItems
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        legendItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DisplayContentLegendCell", for: indexPath)
        let legendItem = legendItems[indexPath.row]
        cell.textLabel?.text = legendItem.name
        cell.imageView?.image = legendItem.image
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Legend"
    }
}

// MARK: - LegendItem
private struct LegendItem {
    let name: String
    let image: UIImage
}

// MARK: - ContainerViewSymbol
struct ContainerViewSymbol {
    let name: String
    let symbol: AGSSymbol
}
