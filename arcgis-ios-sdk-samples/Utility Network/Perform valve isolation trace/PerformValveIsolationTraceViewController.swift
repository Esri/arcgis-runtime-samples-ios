// Copyright 2020 Esri
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

class PerformValveIsolationTraceViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The button to start the trace.
    @IBOutlet weak var traceButton: UIBarButtonItem!
    /// The button to choose a utility category for filter barriers.
    @IBOutlet weak var categoryButton: UIBarButtonItem!
    /// The switch to control whether to include isolated features in the trace results when used in conjunction with an isolation trace.
    @IBOutlet weak var isolationSwitch: UISwitch!
    /// The label to display trace status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap(with: layers)
        }
    }
    
    // MARK: Instance properties
    
    /// The URL to the feature service for running the isolation trace.
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleGas/FeatureServer")!
    
    // Constants for creating the default trace configuration.
    let domainNetworkName = "Pipeline"
    let tierName = "Pipe Distribution System"
    
    // Constants for creating the default starting location.
    let networkSourceName = "Gas Device"
    let assetGroupName = "Meter"
    let assetTypeName = "Customer"
    let globalId = UUID(uuidString: "98A06E95-70BE-43E7-91B7-E34C9D3CB9FF")!
    
    /// An array to keep track of all available utility categories under current network definition.
    var filterBarrierCategories: [AGSUtilityCategory] = []
    var traceConfiguration: AGSUtilityTraceConfiguration?
    var selectedCategory: AGSUtilityCategory?
    var startingLocationElement: AGSUtilityElement!
    var utilityNetwork: AGSUtilityNetwork!
    
    /// The gas line layer ./3 and gas device layer ./0 are created from the feature service URL.
    lazy var layers: [AGSFeatureLayer] = {
        let urls = [
            featureServiceURL.appendingPathComponent("3"),
            featureServiceURL.appendingPathComponent("0")
        ]
        return urls.map { (url) -> AGSFeatureLayer in
            let featureTable = AGSServiceFeatureTable(url: url)
            return AGSFeatureLayer(featureTable: featureTable)
        }
    }()
    
    // MARK: Initialize map and utility network
    
    /// Create a map.
    ///
    /// - Parameter layers: The feature layers for the utility network.
    /// - Returns: An `AGSMap` object.
    func makeMap(with layers: [AGSFeatureLayer]) -> AGSMap {
        let map = AGSMap(basemap: .streetsNightVector())
        // Add the utility network feature layers to the map for display.
        map.operationalLayers.addObjects(from: layers)
        return map
    }
    
    /// Create trace parameters based on the trace configuration from current utility tier and category.
    ///
    /// - Returns: An optional `AGSUtilityTraceParameters` object.
    func makeTraceParameters() -> AGSUtilityTraceParameters? {
        guard let configuration = traceConfiguration else {
            setStatus(message: "Trace configuration does not exist.")
            return nil
        }
        guard let category = selectedCategory else {
            // A nil category will let the trace fail.
            setStatus(message: "Category not set for filter barrier.")
            return nil
        }
        // Note: AGSUtilityNetworkAttributeComparison or AGSUtilityCategoryComparison with AGSUtilityCategoryComparisonOperator.doesNotExist
        // can also be used. These conditions can be joined with either AGSUtilityTraceOrCondition or AGSUtilityTraceAndCondition.
        let comparison = AGSUtilityCategoryComparison(category: category, comparisonOperator: .exists)
        configuration.filter?.barriers = comparison
        configuration.includeIsolatedFeatures = isolationSwitch.isOn
        
        let parameters = AGSUtilityTraceParameters(traceType: .isolation, startingLocations: [startingLocationElement])
        parameters.traceConfiguration = configuration
        return parameters
    }
    
    /// Select to highlight the features in the feature layers.
    ///
    /// - Parameters:
    ///   - elements: The utility elements from the trace result that correspond to `AGSArcGISFeature` objects.
    ///   - completion: Completion closure to execute after all selections are done.
    func selectFeatures(in elements: [AGSUtilityElement], completion: @escaping () -> Void) {
        let groupedElements = Dictionary(grouping: elements) { $0.networkSource.name }
        let selectionGroup = DispatchGroup()
        
        groupedElements.forEach { (networkName, elements) in
            guard let layer = self.layers.first(where: { $0.featureTable?.tableName == networkName }) else { return }
            
            selectionGroup.enter()
            self.utilityNetwork.features(for: elements) { [weak self, layer] (features, error) in
                defer {
                    selectionGroup.leave()
                }
                if let features = features {
                    layer.select(features)
                } else if let error = error {
                    self?.presentAlert(error: error)
                }
            }
        }
        
        selectionGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func loadUtilityNetwork() {
        setStatus(message: "Loading utility network…")
        // Load the utility network to be ready to run a trace against it.
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.setStatus(message: "Loading utility network failed.")
                self.presentAlert(error: error)
            } else {
                let networkDefinition = self.utilityNetwork.definition
                let domainNetwork = networkDefinition.domainNetwork(withDomainNetworkName: self.domainNetworkName)
                let utilityTier = domainNetwork?.tier(withName: self.tierName)
                self.filterBarrierCategories = networkDefinition.categories
                // Get the trace configuration for the specified utility tier.
                self.traceConfiguration = utilityTier?.traceConfiguration
                // Create a trace filter.
                self.traceConfiguration?.filter = AGSUtilityTraceFilter()
                
                // Get a default starting location.
                let networkSource = networkDefinition.networkSource(withName: self.networkSourceName)
                let assetGroup = networkSource?.assetGroup(withName: self.assetGroupName)
                let assetType = assetGroup?.assetType(withName: self.assetTypeName)
                if let type = assetType, let element = self.utilityNetwork.createElement(with: type, globalID: self.globalId) {
                    self.startingLocationElement = element
                    // Draw the starting location element on the map.
                    self.drawStartingLocation()
                    self.setStatus(message: "Utility network loaded.")
                    self.setUIState()
                } else {
                    self.setStatus(message: "Creating starting location failed.")
                }
            }
        }
    }
    
    // MARK: UI and feedback
    
    func drawStartingLocation() {
        // Get a list of features for the starting location element.
        utilityNetwork.features(for: [startingLocationElement]) { [weak self] (features, error) in
            guard let self = self else { return }
            if let features = features {
                if let feature = features.first {
                    // Get the geometry of the first feature for the starting location as a point.
                    if let startingLocationGeometry = feature.geometry as? AGSPoint {
                        // Create a graphic for the starting point and add it to the graphics overlay.
                        let startingPointSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 25)
                        let startingLocationGraphic = AGSGraphic(geometry: startingLocationGeometry, symbol: startingPointSymbol)
                        let startingLocationGraphicsOverlay = AGSGraphicsOverlay()
                        startingLocationGraphicsOverlay.graphics.add(startingLocationGraphic)
                        self.mapView.graphicsOverlays.add(startingLocationGraphicsOverlay)
                        self.mapView.setViewpoint(AGSViewpoint(center: startingLocationGeometry, scale: 3000), completion: nil)
                    } else {
                        self.setStatus(message: "Drawing starting location feature failed.")
                    }
                } else {
                    self.setStatus(message: "Starting location features not found.")
                }
            } else if let error = error {
                self.setStatus(message: "Loading starting location features failed.")
                self.presentAlert(error: error)
            }
        }
    }
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func setUIState() {
        let utilityNetworkIsReady = utilityNetwork.loadStatus == .loaded
        categoryButton.isEnabled = utilityNetworkIsReady
        
        let canTrace = utilityNetworkIsReady && startingLocationElement != nil
        traceButton.isEnabled = canTrace
    }
    
    /// Clear all the feature selections from previous trace.
    func clearLayersSelection() {
        layers.forEach { $0.clearSelection() }
    }
    
    // MARK: - Actions
    
    @IBAction func traceButtonTapped(_ button: UIBarButtonItem) {
        clearLayersSelection()
        guard let parameters = makeTraceParameters() else { return }
        SVProgressHUD.show(withStatus: "Running isolation trace…")
        utilityNetwork.trace(with: parameters) { [weak self] (traceResults, error) in
            guard let self = self else { return }
            if let elementTraceResult = traceResults?.first as? AGSUtilityElementTraceResult,
                !elementTraceResult.elements.isEmpty {
                SVProgressHUD.show(withStatus: "Trace completed. Selecting features…")
                self.selectFeatures(in: elementTraceResult.elements) { [weak self] in
                    self?.setStatus(message: "Trace completed.")
                    SVProgressHUD.dismiss()
                }
            } else if let error = error {
                self.setStatus(message: "Trace failed.")
                self.presentAlert(error: error)
                SVProgressHUD.dismiss()
            } else {
                self.setStatus(message: "Trace completed with no output.")
                SVProgressHUD.dismiss()
            }
        }
    }
    
    @IBAction func categoryButtonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a category for filter barrier.",
            message: nil,
            preferredStyle: .actionSheet
        )
        filterBarrierCategories.forEach { category in
            let action = UIAlertAction(title: category.name, style: .default) { _ in
                self.selectedCategory = category
                self.setStatus(message: "\(category.name) selected.")
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = categoryButton
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["PerformValveIsolationTraceViewController"]
        // Create the utility network, referencing the map.
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: mapView.map!)
        loadUtilityNetwork()
    }
}
