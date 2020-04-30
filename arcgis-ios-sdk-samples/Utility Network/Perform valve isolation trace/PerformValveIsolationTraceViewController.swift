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
    /// a
    @IBOutlet weak var traceButton: UIBarButtonItem!
    /// b
    @IBOutlet weak var categoryButton: UIBarButtonItem!
    /// a switch
    @IBOutlet weak var isolationSwitch: UISwitch!
    /// The 3-line label to display navigation status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    lazy var startingLocationGraphicsOverlay = AGSGraphicsOverlay()
    
    var filterBarrierCategories: [AGSUtilityCategory] = []
    var selectedCategory: AGSUtilityCategory?
    
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleGas/FeatureServer")!
    var startingLocation: AGSUtilityElement?
    var utilityNetwork: AGSUtilityNetwork!
    var traceConfiguration: AGSUtilityTraceConfiguration?
    
    // Create gas distribution line layer ./3 and gas device layer ./0.
    private var layers: [AGSFeatureLayer] {
        return [3, 0].map {
            let featureTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("\($0)"))
            let layer = AGSFeatureLayer(featureTable: featureTable)
            return layer
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsNightVector())
        // Add the utility network feature layers to the map for display.
        map.operationalLayers.addObjects(from: layers)
        return map
    }
    
    func makeUtilityNetwork(on map: AGSMap) {
        // Create the utility network, referencing the map.
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: map)
        // Load the Utility Network to be ready for us to run a trace against it.
        setStatus(message: "Loading Utility Network…")
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.setStatus(message: "Loading Utility Network failed.")
                self.presentAlert(error: error)
                return
            } else {
                let networkDefinition = self.utilityNetwork.definition
                let domainNetwork = networkDefinition.domainNetwork(withDomainNetworkName: "Pipeline")
                let utilityTier = domainNetwork?.tier(withName: "Pipe Distribution System")
                self.traceConfiguration = utilityTier?.traceConfiguration
                
                self.filterBarrierCategories = networkDefinition.categories
                
                // Create a trace filter.
                self.traceConfiguration?.filter = AGSUtilityTraceFilter()
                
                // Get a default starting location.
                let networkSource = networkDefinition.networkSource(withName: "Gas Device")
                let assetGroup = networkSource?.assetGroup(withName: "Meter")
                let assetType = assetGroup?.assetType(withName: "Customer")
                self.startingLocation = self.utilityNetwork.createElement(with: assetType!, globalID: UUID(uuidString: "98A06E95-70BE-43E7-91B7-E34C9D3CB9FF")!)
                
                // Get a list of features for the starting location element.
                self.utilityNetwork.features(for: [self.startingLocation!]) { (features, error) in
                    if let error = error {
                        self.setStatus(message: "Loading starting location features failed.")
                        self.presentAlert(error: error)
                        return
                    } else if features == nil || features!.isEmpty {
                        self.setStatus(message: "Starting location features not found.")
                    } else {
                        // Get the geometry of the first feature for the starting location as a point.
                        if let startingLocationGeometry = features?.first?.geometry as? AGSPoint {
                            // Create a graphic for the starting location and add it to the graphics overlay.
                            let startingPointSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 25)
                            let startingLocationGraphic = AGSGraphic(geometry: startingLocationGeometry, symbol: startingPointSymbol)
                            self.startingLocationGraphicsOverlay.graphics.add(startingLocationGraphic)
                            self.mapView.setViewpoint(AGSViewpoint(center: startingLocationGeometry, scale: 3000), completion: nil)
                            self.setStatus(message: "Utility Network loaded.")
                            self.setUIState()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: UI and Feedback
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func setUIState() {
        let utilityNetworkIsReady = utilityNetwork.loadStatus == .loaded
        categoryButton.isEnabled = utilityNetworkIsReady
        
        let canTrace = utilityNetworkIsReady && startingLocation != nil
        traceButton.isEnabled = canTrace
    }
    
    func clearLayesSelection() {
        self.mapView.map?.operationalLayers.lazy
            .compactMap { $0 as? AGSFeatureLayer }
            .forEach { $0.clearSelection() }
    }
    
    // MARK: - Actions
    
    @IBAction func traceButtonTapped(_ button: UIBarButtonItem) {
        SVProgressHUD.show(withStatus: "Running isolation trace…")
        if let category = selectedCategory {
            let comparison = AGSUtilityCategoryComparison(category: category, comparisonOperator: .exists)
            traceConfiguration?.filter?.barriers = comparison
        }
        traceConfiguration?.includeIsolatedFeatures = isolationSwitch.isOn
        
        if let start = startingLocation {
            let parameters = AGSUtilityTraceParameters(traceType: .isolation, startingLocations: [start])
            parameters.traceConfiguration = traceConfiguration
            utilityNetwork.trace(with: parameters) { [weak self] (traceResults, error) in
                guard let self = self else { return }
                if let error = error {
                    self.setStatus(message: "Trace failed.")
                    self.presentAlert(error: error)
                    SVProgressHUD.dismiss()
                    return
                }
                guard let elementTraceResult = traceResults?.first as? AGSUtilityElementTraceResult, !elementTraceResult.elements.isEmpty else {
                    self.setStatus(message: "Trace completed with no output.")
                    SVProgressHUD.dismiss()
                    return
                }
                self.clearLayesSelection()
                SVProgressHUD.show(withStatus: "Trace completed. Selecting features…")
                let groupedElements = Dictionary(grouping: elementTraceResult.elements) { $0.networkSource.name }
                
                let selectionGroup = DispatchGroup()

                groupedElements.forEach { (networkName, elements) in
                    guard let layer = self.mapView.map?.operationalLayers.first(where: { ($0 as? AGSFeatureLayer)?.featureTable?.tableName == networkName }) as? AGSFeatureLayer else { return }
                    
                    selectionGroup.enter()
                    self.utilityNetwork.features(for: elements) { [layer] (features, error) in
                        defer {
                            selectionGroup.leave()
                        }
                        if let error = error {
                            self.setStatus(message: "Selecting features failed.")
                            self.presentAlert(error: error)
                            return
                        }
                        guard let features = features else { return }
                        layer.select(features)
                    }
                }
                
                selectionGroup.notify(queue: .main) { [weak self] in
                    self?.setStatus(message: "Trace completed.")
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    @IBAction func categoryButtonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Choose category for filter barrier", message: nil, preferredStyle: .actionSheet)
        filterBarrierCategories.forEach { category in
            let action = UIAlertAction(title: category.name, style: .default) { [unowned self] _ in
                self.selectedCategory = category
                self.setStatus(message: "\(category.name) selected.")
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = categoryButton
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["PerformValveIsolationTraceViewController"]
        makeUtilityNetwork(on: mapView.map!)
    }
}
