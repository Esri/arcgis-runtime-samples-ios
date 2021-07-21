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
    static let featureServiceURL = URL(
        string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleGas/FeatureServer"
    )!
    
    static let filterBarrierIdentifier = "filter barrier"
    
    // MARK: Instance properties
    
    let utilityNetwork = AGSUtilityNetwork(url: featureServiceURL)
    let serviceGeodatabase = AGSServiceGeodatabase(url: featureServiceURL)
    var traceCompleted = false
    var identifyAction: AGSCancelable?
    
    /// The base trace parameters.
    let traceParameters = AGSUtilityTraceParameters(traceType: .isolation, startingLocations: [])
    /// The utility category selected for running the trace.
    var selectedCategory: AGSUtilityCategory?
    /// An array of available utility categories with current network definition.
    var filterBarrierCategories = [AGSUtilityCategory]()
    /// An array to hold the gas line and gas device feature layers created from
    /// the service geodatabase.
    var layers = [AGSFeatureLayer]()
    /// The point geometry of the starting location.
    var startingLocationPoint: AGSPoint!
    
    /// The graphic overlay to display starting location and filter barriers.
    let parametersOverlay: AGSGraphicsOverlay = {
        let barrierPointSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let barrierUniqueValue = AGSUniqueValue(
            description: "Filter Barrier",
            label: "Filter Barrier",
            symbol: barrierPointSymbol,
            values: [filterBarrierIdentifier]
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
        // Add the not yet loaded utility network to the map.
        map.utilityNetworks.add(utilityNetwork)
        return map
    }
    
    /// Load the service geodatabase and initialize the layers.
    func loadServiceGeodatabase() {
        UIApplication.shared.showProgressHUD(message: "Loading service geodatabase…")
        // NOTE: Never hardcode login information in a production application.
        // This is done solely for the sake of the sample.
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
            } else {
                UIApplication.shared.hideProgressHUD()
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
            if let error = error {
                UIApplication.shared.hideProgressHUD()
                self.presentAlert(error: error)
                self.setStatus(message: errorMessage)
            } else if let startingLocation = self.makeStartingLocation() {
                self.utilityNetworkDidLoad(startingLocation: startingLocation)
            } else {
                UIApplication.shared.hideProgressHUD()
                self.presentAlert(message: "Failed to create starting location.")
                self.setStatus(message: errorMessage)
            }
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
                self.mapView.setViewpointCenter(startingLocationPoint, scale: 3_000)
                // Get available utility categories.
                self.filterBarrierCategories = self.utilityNetwork.definition.categories
                self.categoryBarButtonItem.isEnabled = true
                // Enable touch event detection on the map view.
                self.mapView.touchDelegate = self
                self.setStatus(
                    message: """
                    Utility network loaded.
                    Tap on the map to add filter barriers or run the trace directly without filter barriers.
                    """
                )
            } else if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Failed to load starting location features.")
            }
        }
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
    func makeTraceConfiguration(category: AGSUtilityCategory?) -> AGSUtilityTraceConfiguration? {
        // Get a default trace configuration from a tier in the network.
        guard let configuration = utilityNetwork
                .definition
                .domainNetwork(withDomainNetworkName: "Pipeline")?
                .tier(withName: "Pipe Distribution System")?
                .makeDefaultTraceConfiguration()
        else {
            return nil
        }
        if let category = category {
            // Note: `AGSUtilityNetworkAttributeComparison` or `AGSUtilityCategoryComparison`
            // with `AGSUtilityCategoryComparisonOperator.doesNotExist` can also be used.
            // These conditions can be joined with either `AGSUtilityTraceOrCondition`
            // or `AGSUtilityTraceAndCondition`.
            // See more in the README.
            let comparison = AGSUtilityCategoryComparison(category: category, comparisonOperator: .exists)
            // Create a trace filter.
            let filter = AGSUtilityTraceFilter()
            filter.barriers = comparison
            configuration.filter = filter
        } else {
            configuration.filter = nil
        }
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
            utilityNetwork.features(for: elements) { [weak self, layer] (features, error) in
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
        guard let configuration = makeTraceConfiguration(category: selectedCategory) else {
            setStatus(message: "Failed to get trace configuration.")
            return
        }
        traceParameters.traceConfiguration = configuration
        
        utilityNetwork.trace(with: traceParameters) { [weak self] traceResults, error in
            guard let self = self else { return }
            if let elementTraceResult = traceResults?.first as? AGSUtilityElementTraceResult,
               !elementTraceResult.elements.isEmpty {
                self.selectFeatures(in: elementTraceResult.elements) {
                    if let categoryName = self.selectedCategory?.name.lowercased() {
                        self.setStatus(message: "Trace with \(categoryName) category completed.")
                    } else {
                        self.setStatus(message: "Trace with filter barriers completed.")
                    }
                }
            } else if let error = error {
                self.setStatus(message: "Trace failed.")
                self.presentAlert(error: error)
            } else {
                self.setStatus(message: "Trace completed with no output.")
            }
            completion()
        }
    }
    
    @IBAction func traceResetButtonTapped(_ button: UIBarButtonItem) {
        if traceCompleted {
            // Reset the trace if it is already completed
            clearLayersSelection()
            traceParameters.filterBarriers.removeAll()
            parametersOverlay.graphics.removeAllObjects()
            traceCompleted = false
            selectedCategory = nil
            // Add back the starting location.
            addGraphic(for: startingLocationPoint, traceLocationType: "starting point")
            mapView.setViewpointCenter(startingLocationPoint, scale: 3_000)
            // Set UI state.
            setStatus(message: "Tap on the map to add filter barriers, or run the trace directly without filter barriers.")
            traceResetBarButtonItem.title = "Trace"
            traceResetBarButtonItem.isEnabled = false
            categoryBarButtonItem.isEnabled = true
            isolationSwitch.isEnabled = true
        } else {
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

// MARK: - AGSGeoViewTouchDelegate

extension PerformValveIsolationTraceViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Don't identify taps if trace has completed.
        guard !traceCompleted else { return }
        identifyAction?.cancel()
        // Turn off user interaction to avoid unintended touch during identify.
        mapView.isUserInteractionEnabled = false
        identifyAction = mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [weak self] result, error in
            guard let self = self else { return }
            if let feature = result?.first?.geoElements.first as? AGSArcGISFeature {
                self.addFilterBarrier(for: feature, at: mapPoint)
            } else if let error = error {
                self.setStatus(message: "Error identifying trace locations.")
                self.presentAlert(error: error)
            }
            self.mapView.isUserInteractionEnabled = true
        }
    }
    
    /// Add a graphic at the tapped location for the filter barrier.
    /// - Parameters:
    ///   - feature: The geoelement retrieved as an `AGSFeature`.
    ///   - location: The `AGSPoint` used to identify utility elements in the utility network.
    func addFilterBarrier(for feature: AGSArcGISFeature, at location: AGSPoint) {
        guard let geometry = feature.geometry,
              let element = utilityNetwork.createElement(with: feature) else {
            return
        }
        let elementDidSet = { [weak self] in
            guard let self = self else { return }
            if self.categoryBarButtonItem.isEnabled {
                self.categoryBarButtonItem.isEnabled = false
                self.selectedCategory = nil
            }
            if !self.traceResetBarButtonItem.isEnabled {
                self.traceResetBarButtonItem.isEnabled = true
            }
            self.traceParameters.filterBarriers.append(element)
            let point = geometry as? AGSPoint ?? location
            self.addGraphic(for: point, traceLocationType: Self.filterBarrierIdentifier)
        }
        
        switch element.networkSource.sourceType {
        case .junction:
            // If the user tapped on a junction, get the asset's terminal(s).
            if let terminals = element.assetType.terminalConfiguration?.terminals {
                selectTerminal(from: terminals, at: location) { [weak self] terminal in
                    guard let self = self else { return }
                    element.terminal = terminal
                    elementDidSet()
                    self.setStatus(message: String(format: "Juntion element with terminal %@ added to the filter barriers.", terminal.name))
                }
            }
        case .edge:
            // If the user tapped on an edge, determine how far along that edge.
            if let line = AGSGeometryEngine.geometryByRemovingZ(from: geometry) as? AGSPolyline {
                element.fractionAlongEdge = AGSGeometryEngine.fraction(alongLine: line, to: location, tolerance: -1)
                elementDidSet()
                setStatus(message: String(format: "Edge element at fractionAlongEdge %.3f added to the filter barriers.", element.fractionAlongEdge))
            }
        @unknown default:
            return
        }
    }
    
    /// Presents an action sheet to select one from multiple terminals, or return if there is only one.
    /// - Parameters:
    ///   - terminals: An array of terminals.
    ///   - mapPoint: The location tapped on the map.
    ///   - completion: Completion closure to pass the selected terminal.
    func selectTerminal(from terminals: [AGSUtilityTerminal], at mapPoint: AGSPoint, completion: @escaping (AGSUtilityTerminal) -> Void) {
        if terminals.count > 1 {
            // Show a terminal picker
            let terminalPicker = UIAlertController(
                title: "Select a terminal.",
                message: nil,
                preferredStyle: .actionSheet
            )
            terminals.forEach { terminal in
                let action = UIAlertAction(title: terminal.name, style: .default) { [terminal] _ in
                    completion(terminal)
                }
                terminalPicker.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            terminalPicker.addAction(cancelAction)
            if let popoverController = terminalPicker.popoverPresentationController {
                // If presenting in a split view controller (e.g. on an iPad),
                // provide positioning information for the alert controller.
                popoverController.sourceView = mapView
                let tapPoint = mapView.location(toScreen: mapPoint)
                popoverController.sourceRect = CGRect(origin: tapPoint, size: .zero)
            }
            present(terminalPicker, animated: true)
        } else if let terminal = terminals.first {
            completion(terminal)
        }
    }
}
