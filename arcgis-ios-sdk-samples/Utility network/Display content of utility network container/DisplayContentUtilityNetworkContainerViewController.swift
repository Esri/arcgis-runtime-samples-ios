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

class DisplayContentUtilityNetworkContainerViewController: UIViewController, AGSGeoViewTouchDelegate {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(
                url: URL(string: "https://sampleserver7.arcgisonline.com/portal/home/item.html?id=813eda749a9444e4a9d833a4db19e1c8")!
            )
            mapView.setViewpoint(AGSViewpoint(latitude: 41.801504, longitude: -88.163718, scale: 4e3))
            // Add a graphics overlay.
            mapView.graphicsOverlays.add(graphicsOverlay)
        }
    }
    /// The bar button item to prompt return of the main view.
    @IBOutlet var exitBarButtonItem: UIBarButtonItem!
    @IBOutlet var legendBarButtonItem: UIBarButtonItem!
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    var utilityNetwork: AGSUtilityNetwork!
    let graphicsOverlay = AGSGraphicsOverlay()
    /// The default or previous viewpoint before entering the container view.
    var previousViewpoint: AGSViewpoint?
    var featureLayers = [AGSFeatureLayer]()
    
    // The symbols used to display the container view contents.
    private let boundingBoxSymbol = ContainerViewSymbol(
        name: "Bounding box",
        symbol: AGSSimpleLineSymbol(style: .dash, color: .yellow, width: 3)
    )
    private let attachmentSymbol = ContainerViewSymbol(
        name: "Attachment",
        symbol: AGSSimpleLineSymbol(style: .dot, color: .green, width: 3)
    )
    private let connectivitySymbol = ContainerViewSymbol(
        name: "Connectivity",
        symbol: AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
    )
    
    /// The data source for the legend table.
    private var symbolsDataSource: SymbolsDataSource?
    
    /// The action that is prompted when exiting the container view.
    @IBAction func exitContainerView() {
        // Disable the bar button item since container view will be exited.
        exitBarButtonItem.isEnabled = false
        // Remove all the objects that were added onto the graphics overlay.
        graphicsOverlay.graphics.removeAllObjects()
        (mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
            // Make each operational layer visible.
            layer.isVisible = true
        }
        if let previousViewpoint = previousViewpoint {
            // Return to the viewpoint before container view was entered.
            mapView.setViewpoint(previousViewpoint) { [weak self] _ in
                // Enable interaction on the map view.
                self?.mapView.isUserInteractionEnabled = true
            }
        }
    }
    
    /// Create and load the utility network using the feature service URL.
    func createAndLoadUtilityNetwork() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: mapView.map!)
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
        var accumulatedLegendInfos = [AGSLegendInfo]()
        let legendGroup = DispatchGroup()
        // Create feature layers using the feature tables.
        featureLayers = [electricDistributionTable, structureJunctionTable].map(AGSFeatureLayer.init)
        featureLayers.forEach { layer in
            legendGroup.enter()
            // Get the legend information of each layer.
            layer.fetchLegendInfos { legendInfos, _ in
                defer { legendGroup.leave() }
                accumulatedLegendInfos.append(contentsOf: legendInfos!)
            }
        }
        legendGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let featureLayerSymbols: [(String, AGSSymbol)] = accumulatedLegendInfos.compactMap { legendInfo in
                if !legendInfo.name.isEmpty,
                   let symbol = legendInfo.symbol {
                    return (legendInfo.name, symbol)
                } else {
                    return nil
                }
            }
            let symbolsDictionary = Dictionary(featureLayerSymbols +
                                        [("Bounding box", self.boundingBoxSymbol.symbol),
                                         ("Attachment", self.attachmentSymbol.symbol),
                                         ("Connectivity", self.connectivitySymbol.symbol)], uniquingKeysWith: { (first, _) in first })
            self.makeLegendItems(symbols: symbolsDictionary) { legendItems in
                self.symbolsDataSource = SymbolsDataSource(legendItems: legendItems.sorted { $0.name < $1.name })
                self.legendBarButtonItem.isEnabled = true
            }
        }
    }
    
    /// Create swatches from the provided symbols.
    ///
    /// - Parameters:
    ///     - legend: The array containing all of the symbols and their names.
    ///     - completion: A closure to pass back the legend with cached images.
    private func makeLegendItems(symbols: [String: AGSSymbol], completion: @escaping ([LegendItem]) -> Void) {
        let swatchGroup = DispatchGroup()
        var legendItems = [LegendItem]()
        symbols.forEach { symbolItem in
            let symbol = symbolItem.value
            swatchGroup.enter()
            symbol.createSwatch(withBackgroundColor: nil, screen: .main) { image, _ in
                defer { swatchGroup.leave() }
                guard let image = image else { return }
                legendItems.append(LegendItem(name: symbolItem.key, image: image))
            }
        }
        swatchGroup.notify(queue: .main) {
            completion(legendItems)
        }
    }
    
    /// Get the container feature that was tapped on.
    ///
    /// - Parameters:
    ///   - layerResults: The layer results identified by the touch delegate.
    ///   - completion: A closure to pass back the feature that was tapped on.
    func identifyContainerFeature(layerResults: [AGSIdentifyLayerResult]) {
        // A map containing SubtypeFeatureLayer is expected to have features as part of its sublayer's result.
        guard let layerResult = layerResults.first(where: { $0.layerContent is AGSSubtypeFeatureLayer }) else { return }
        layerResult.sublayerResults
            .flatMap { $0.geoElements.compactMap { $0 as? AGSArcGISFeature } }
            .forEach(addElementAssociations(for:))
    }
    
    /// Get the containment associations from the chosen element.
    ///
    /// - Parameter containerFeature: The selected container feature
    func addElementAssociations(for containerFeature: AGSArcGISFeature) {
        // Create a container element using the selected feature.
        guard let containerElement = utilityNetwork!.createElement(with: containerFeature) else { return }
        // Get the containment associations from this element to display its content.
        utilityNetwork!.associations(with: containerElement, type: .containment) { [weak self] containmentAssociations, _ in
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
        setOperationalLayersVisibility(isVisible: false)
        // Get the corresponding features for the array of content elements.
        utilityNetwork?.features(for: contentElements) { [weak self] (contentFeatures, error) in
            guard let self = self else { return }
            if let contentFeatures = contentFeatures {
                // Create and add a symbol for each of the features.
                let graphics: [AGSGraphic] = contentFeatures.compactMap { (feature) in
                    guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
                          let symbol = featureTable.layerInfo?.drawingInfo?.renderer?.symbol(for: feature) else {
                        return nil
                    }
                    return AGSGraphic(geometry: feature.geometry, symbol: symbol)
                }
                self.graphicsOverlay.graphics.addObjects(from: graphics)
                // Set the bounding box which defines the container view may be computed using the extent of the features it contains or centered around its geometry at the container's view scale.
                if contentFeatures.count == 1,
                   let point = contentFeatures.first?.geometry as? AGSPoint {
                    self.mapView.setViewpointCenter(point, scale: containerElement.assetType.containerViewScale) { _ in
                        self.presentAlert(title: nil, message: "This feature contains no associations.")
                        guard let boundingBox = self.mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry else { return }
                        self.identifyAssociationsWithExtent(boundingBox: boundingBox)
                    }
                } else {
                    let boundingBox = AGSGeometryEngine.bufferGeometry(self.graphicsOverlay.extent, byDistance: 0.05)
                    self.identifyAssociationsWithExtent(boundingBox: boundingBox!)
                }
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Change the visibility of the operational layers.
    ///
    /// - Parameter isVisible: A boolean to make the map visible or not.
    func setOperationalLayersVisibility(isVisible: Bool) {
        let operationlLayers = mapView.map!.operationalLayers as! [AGSLayer]
        operationlLayers.forEach { $0.isVisible = isVisible }
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
            self.utilityNetwork?.associations(withExtent: self.graphicsOverlay.extent) { [weak self] containmentAssociations, _ in
                guard let self = self, let containmentAssociations = containmentAssociations else { return }
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
            if let layerResults = layerResults, !layerResults.isEmpty {
                self.identifyContainerFeature(layerResults: layerResults)
            } else {
                if let error = error {
                    self.presentAlert(error: error)
                }
                self.mapView.isUserInteractionEnabled = true
            }
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AGSAuthenticationManager.shared().delegate = self
        // Load the utility network.
        createAndLoadUtilityNetwork()
        // Get the legends from the feature service.
        fetchLegendInfo()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayContentUtilityNetworkContainerViewController"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayContentLegendSegue",
           let controller = segue.destination as? UITableViewController {
            controller.presentationController?.delegate = self
            controller.tableView.dataSource = symbolsDataSource
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension DisplayContentUtilityNetworkContainerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - AGSAuthenticationManagerDelegate

extension DisplayContentUtilityNetworkContainerViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        let credential = AGSCredential(user: "viewer01", password: "I68VGU^nMurF")
        challenge.continue(with: credential)
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

private struct ContainerViewSymbol {
    let name: String
    let symbol: AGSSymbol
}
