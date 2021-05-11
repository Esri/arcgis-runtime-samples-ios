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
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(parametersOverlay)
        }
    }
    
    /// The button to start or reset the trace.
    @IBOutlet var traceResetBarButtonItem: UIBarButtonItem! {
        didSet {
            traceResetBarButtonItem.possibleTitles = ["Trace", "Reset"]
        }
    }
    /// The button to choose a utility category for filter barriers.
    @IBOutlet var categoryBarButtonItem: UIBarButtonItem!
    /// The switch to control whether to include isolated features in the
    /// trace results when used in conjunction with an isolation trace.
    @IBOutlet var isolationSwitch: UISwitch!
    /// The label to display trace status.
    @IBOutlet var statusLabel: UILabel!
    
    // MARK: Constant
    
    /// The URL to the feature service for running the isolation trace.
    static let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleGas/FeatureServer")!
    
    // MARK: Instance properties
    
    let utilityNetwork = AGSUtilityNetwork(url: featureServiceURL)
    let serviceGeodatabase = AGSServiceGeodatabase(url: featureServiceURL)
    var traceCompleted = false
    
    /// The base trace parameters.
    let traceParameters = AGSUtilityTraceParameters(traceType: .isolation, startingLocations: [])
    /// The utility category selected for running the trace.
    var selectedCategory: AGSUtilityCategory?
    /// An array of available utility categories with current network definition.
    var filterBarrierCategories: [AGSUtilityCategory]!
    /// An array to hold the gas line and gas device feature layers created from
    /// the service geodatabase.
    var layers: [AGSFeatureLayer]!
    /// The point geometry of the starting location.
    var startingLocationPoint: AGSPoint!
    
    /// The graphic overlay to display starting location and filter barriers.
    let parametersOverlay: AGSGraphicsOverlay = {
        let barrierPointSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let barrierUniqueValue = AGSUniqueValue(
            description: "Filter Barrier",
            label: "Filter Barrier",
            symbol: barrierPointSymbol,
            values: ["filter barrier"]
        )
        let startingPointSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 20)
        let renderer = AGSUniqueValueRenderer(
            fieldNames: ["TraceLocationType"],
            uniqueValues: [barrierUniqueValue],
            defaultLabel: "Starting Location",
            defaultSymbol: startingPointSymbol
        )
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = renderer
        return overlay
    }()
    
    // MARK: Initialize map and utility network
    
    /// Create a map with a utility network.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISStreetsNight)
        // Add the not loaded utility network to the map.
        map.utilityNetworks.add(utilityNetwork)
        return map
    }
    
    /// Load the service geodatabase and initialize the layers.
    func loadServiceGeodatabase() {
        UIApplication.shared.showProgressHUD(message: "Loading service geodatabase…")
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        serviceGeodatabase.credential = AGSCredential(user: "viewer01", password: "I68VGU^nMurF")
        serviceGeodatabase.load { [weak self] error in
            guard let self = self else { return }
            // The gas device layer ./0 and gas line layer ./3 are created
            // from the service geodatabase.
            if let gasDeviceLayerTable = self.serviceGeodatabase.table(withLayerID: 0),
               let gasLineLayerTable = self.serviceGeodatabase.table(withLayerID: 3) {
                let layers = [gasLineLayerTable, gasDeviceLayerTable].map(AGSFeatureLayer.init)
                // Add the utility network feature layers to the map for display.
                self.mapView.map?.operationalLayers.addObjects(from: layers)
                self.layers = layers
                self.loadUtilityNetwork()
            } else if let error = error {
                UIApplication.shared.hideProgressHUD()
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Load the utility network.
    func loadUtilityNetwork() {
        UIApplication.shared.showProgressHUD(message: "Loading utility network…")
        // Load the utility network to be ready to run a trace against it.
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            let errorMessage = "Failed to load utility network."
            guard error == nil else {
                UIApplication.shared.hideProgressHUD()
                self.presentAlert(error: error!)
                self.setStatus(message: errorMessage)
                return
            }
            // Create a default starting location.
            guard let startingLocation = self.makeStartingLocation() else {
                UIApplication.shared.hideProgressHUD()
                self.presentAlert(message: "Fail to create starting location.")
                self.setStatus(message: errorMessage)
                return
            }
            self.utilityNetworkDidLoad(startingLocation: startingLocation)
        }
    }
    
    /// Called in response to the utility network load operation completing.
    /// - Parameter startingLocation: The utility element to start the trace from.
    func utilityNetworkDidLoad(startingLocation: AGSUtilityElement) {
        traceParameters.startingLocations.append(startingLocation)
        UIApplication.shared.showProgressHUD(message: "Getting starting location feature…")
        // Get the feature for the starting location element.
        utilityNetwork.features(for: traceParameters.startingLocations) { [weak self] features, error in
            UIApplication.shared.hideProgressHUD()
            guard let self = self else { return }
            if let features = features,
               let feature = features.first,
               let startingLocationPoint = feature.geometry as? AGSPoint {
                // Get the geometry of the starting location as a point.
                // Then draw the starting location on the map.
                self.startingLocationPoint = startingLocationPoint
                self.addGraphic(for: startingLocationPoint, traceLocationType: "starting point")
                self.mapView.setViewpointCenter(startingLocationPoint, scale: 3000, completion: nil)
            } else if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Failed to load starting location features.")
            }
        }
        // Get available utility categories.
        let networkDefinition = self.utilityNetwork.definition
        self.filterBarrierCategories = networkDefinition.categories
        self.setStatus(message: "Utility network loaded.")
        self.categoryBarButtonItem.isEnabled = true
        // Enable touch event detection on the map view.
        self.mapView.touchDelegate = self
    }
    
    // MARK: Factory methods
    
    /// When the utility network is loaded, create an `AGSUtilityElement`
    /// from the asset type to use as the starting location for the trace.
    func makeStartingLocation() -> AGSUtilityElement? {
        // Constants for creating the default starting location.
        let networkSourceName = "Gas Device"
        let assetGroupName = "Meter"
        let assetTypeName = "Customer"
        let terminalName = "Load"
        let globalID = UUID(uuidString: "98A06E95-70BE-43E7-91B7-E34C9D3CB9FF")!
        
        // Create a default starting location.
        if let networkSource = utilityNetwork.definition.networkSource(withName: networkSourceName),
           let assetType = networkSource.assetGroup(withName: assetGroupName)?.assetType(withName: assetTypeName),
           let startingLocation = utilityNetwork.createElement(with: assetType, globalID: globalID) {
            // Set the terminal for the location. (For our case, use the "Load" terminal.)
            startingLocation.terminal = assetType.terminalConfiguration?.terminals.first(where: { $0.name == terminalName })
            return startingLocation
        } else {
            return nil
        }
    }
    
    /// Get the utility tier's trace configuration and apply category comparison.
    func makeTraceConfiguration(category: AGSUtilityCategory) -> AGSUtilityTraceConfiguration? {
        // Get a default trace configuration from a tier in the network.
        guard let configuration = utilityNetwork
                .definition
                .domainNetwork(withDomainNetworkName: "Pipeline")?
                .tier(withName: "Pipe Distribution System")?
                .traceConfiguration
        else {
            return nil
        }
        // Note: `AGSUtilityNetworkAttributeComparison` or `AGSUtilityCategoryComparison`
        // with `AGSUtilityCategoryComparisonOperator.doesNotExist` can also be used.
        // These conditions can be joined with either `AGSUtilityTraceOrCondition`
        // or `AGSUtilityTraceAndCondition`.
        let comparison = AGSUtilityCategoryComparison(category: category, comparisonOperator: .exists)
        // Create a trace filter.
        let filter = AGSUtilityTraceFilter()
        filter.barriers = comparison
        configuration.filter = filter
        configuration.includeIsolatedFeatures = isolationSwitch.isOn
        return configuration
    }
    
    // MARK: UI and feedback
    
    /// Select to highlight the features in the feature layers.
    /// - Parameters:
    ///   - elements: The utility elements from the trace result that correspond to `AGSArcGISFeature` objects.
    ///   - completion: Completion closure to execute after all selections are done.
    func selectFeatures(in elements: [AGSUtilityElement], completion: @escaping () -> Void) {
        let groupedElements = Dictionary(grouping: elements) { $0.networkSource.name }
        let selectionGroup = DispatchGroup()
        
        groupedElements.forEach { (networkName, elements) in
            guard let layer = layers.first(where: { $0.featureTable?.tableName == networkName }) else { return }
            
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
    
    func addGraphic(for location: AGSPoint, traceLocationType: String) {
        let traceLocationGraphic = AGSGraphic(geometry: location, symbol: nil, attributes: ["TraceLocationType": traceLocationType])
        parametersOverlay.graphics.add(traceLocationGraphic)
    }
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    /// Clear all the feature selections from previous trace.
    func clearLayersSelection() {
        layers.forEach { $0.clearSelection() }
    }
    
    // MARK: Actions
    
    func trace(completion: @escaping () -> Void) {
        guard let configuration = makeTraceConfiguration(category: selectedCategory!) else {
            setStatus(message: "Fail to get trace configuration.")
            return
        }
        traceParameters.traceConfiguration = configuration
        
        utilityNetwork.trace(with: traceParameters) { [weak self] (traceResults, error) in
            guard let self = self else { return }
            let categoryName = self.selectedCategory!.name.lowercased()
            if let elementTraceResult = traceResults?.first as? AGSUtilityElementTraceResult,
               !elementTraceResult.elements.isEmpty {
                self.selectFeatures(in: elementTraceResult.elements) {
                    self.setStatus(message: "Trace with \(categoryName) category completed.")
                }
            } else if let error = error {
                self.setStatus(message: "Trace with \(categoryName) category failed.")
                self.presentAlert(error: error)
            } else {
                self.setStatus(message: "Trace with \(categoryName) category completed with no output.")
            }
            completion()
        }
    }
    
    @IBAction func traceResetButtonTapped(_ button: UIBarButtonItem) {
        switch traceCompleted {
        case true:
            // Reset the trace if it is already completed
            clearLayersSelection()
            parametersOverlay.graphics.removeAllObjects()
            // Add back the starting location.
            // Get the geometry of the first feature for the starting location as a point.
            addGraphic(for: startingLocationPoint, traceLocationType: "starting point")
            mapView.setViewpointCenter(startingLocationPoint, scale: 3000, completion: nil)
            setStatus(message: "Instructions shown here.")
            traceResetBarButtonItem.title = "Trace"
            traceResetBarButtonItem.isEnabled = false
            categoryBarButtonItem.isEnabled = true
            isolationSwitch.isEnabled = true
            traceCompleted = false
            selectedCategory = nil
        case false:
            UIApplication.shared.showProgressHUD(message: "Running isolation trace…")
            // Run the trace.
            trace { [weak self] in
                UIApplication.shared.hideProgressHUD()
                guard let self = self else { return }
                self.traceResetBarButtonItem.title = "Reset"
                self.categoryBarButtonItem.isEnabled = false
                self.isolationSwitch.isEnabled = false
                self.traceCompleted = true
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
            let action = UIAlertAction(title: category.name, style: .default) { [self] _ in
                selectedCategory = category
                setStatus(message: "\(category.name) selected.")
                traceResetBarButtonItem.isEnabled = true
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = categoryBarButtonItem
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["PerformValveIsolationTraceViewController"]
        // Load the service geodatabase and utility network.
        setStatus(message: "Loading utility network…")
        loadServiceGeodatabase()
    }
}

extension PerformValveIsolationTraceViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
    }
}
