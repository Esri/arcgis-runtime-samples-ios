// Copyright 2019 Esri.
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

private let barrierAttributeValue = "barrier"

class TraceUtilityNetworkViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView!

    @IBOutlet weak var traceNetworkButton: UIBarButtonItem!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    @IBOutlet weak var typeButton: UIBarButtonItem!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var modeControl: UISegmentedControl!
    
    private let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    
    // Create electrical distribution line layer ./115 and electrical device layer ./100.
    private var layers: [AGSFeatureLayer] {
        return [115, 100].map {
            let featureTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("\($0)"))
            let layer = AGSFeatureLayer(featureTable: featureTable)
            if $0 == 115 {
                // Define a solid line for medium voltage lines and a dashed line for low voltage lines.
                let darkCyan = UIColor(red: 0, green: 0.55, blue: 0.55, alpha: 1)
                let mediumVoltageValue = AGSUniqueValue(description: "N/A",
                                                        label: "Medium voltage",
                                                        symbol: AGSSimpleLineSymbol(style: .solid, color: darkCyan, width: 3),
                                                        values: [5])
                let lowVoltageValue = AGSUniqueValue(description: "N/A",
                                                     label: "Low voltage",
                                                     symbol: AGSSimpleLineSymbol(style: .dash, color: darkCyan, width: 3),
                                                     values: [3])
                layer.renderer = AGSUniqueValueRenderer(fieldNames: ["ASSETGROUP"],
                                                        uniqueValues: [mediumVoltageValue, lowVoltageValue],
                                                        defaultLabel: "",
                                                        defaultSymbol: AGSSimpleLineSymbol()
                )
            }
            return layer
        }
    }

    private let map: AGSMap
    private let utilityNetwork: AGSUtilityNetwork
    private var utilityTier: AGSUtilityTier?
    private var traceType = ("Connected", AGSUtilityTraceType.connected)
    private var traceParameters = AGSUtilityTraceParameters(traceType: .connected, startingLocations: [])

    private let parametersOverlay: AGSGraphicsOverlay = {
        let barrierPointSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let barrierUniqueValue = AGSUniqueValue(description: "Barriers",
                                                label: "Barrier",
                                                symbol: barrierPointSymbol,
                                                values: [barrierAttributeValue])

        let startingPointSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 20)
        let renderer = AGSUniqueValueRenderer(fieldNames: ["TraceLocationType"],
                                              uniqueValues: [barrierUniqueValue],
                                              defaultLabel: "Starting Point",
                                              defaultSymbol: startingPointSymbol)

        let overlay = AGSGraphicsOverlay()
        overlay.renderer = renderer

        return overlay
    }()
    
    // MARK: Initialize map and Utility Network
    required init?(coder aDecoder: NSCoder) {
        // Create the map
        map = AGSMap(basemap: .streetsNightVector())
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -9813547.35557238, yMin: 5129980.36635111, xMax: -9813185.0602376, yMax: 5130215.41254146, spatialReference: .webMercator()))

        // Create the utility network, referencing the map.
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: map)

        super.init(coder: aDecoder)
        
        // Add the utility network feature layers to the map for display.
        map.operationalLayers.addObjects(from: layers)
    }
    
    // MARK: Initialize user interface
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TraceUtilityNetworkViewController"]
        
        // Initialize the UI
        setUIState()

        // Set up the map view
        mapView.map = map
        mapView.graphicsOverlays.add(parametersOverlay)
        mapView.touchDelegate = self
        // Set the selection color for features in the map view.
        mapView.selectionProperties = AGSSelectionProperties(color: .yellow)
        
        // Load the Utility Network to be ready for us to run a trace against it.
        setStatus(message: "Loading Utility Network…")
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.setStatus(message: "Loading Utility Network failed")
                self.presentAlert(error: error)
            } else {
                // Update the UI to allow network traces to be run.
                self.setUIState()
                self.setInstructionMessage()
                // Get the utility tier used for traces in this network.
                // For this data set, the "Medium Voltage Radial" tier from the "ElectricDistribution" domain network is used.
                let domainNetwork = self.utilityNetwork.definition.domainNetwork(withDomainNetworkName: "ElectricDistribution")
                self.utilityTier = domainNetwork?.tier(withName: "Medium Voltage Radial")
            }
        }
    }
    
    // MARK: Set trace start points and barriers
    var identifyAction: AGSCancelable?
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let identifyAction = identifyAction {
            identifyAction.cancel()
        }

        setStatus(message: "Identifying trace locations…")
        identifyAction = mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [weak self] (result, error) in
            guard let self = self else { return }
            if let error = error {
                self.setStatus(message: "Error identifying trace locations.")
                self.presentAlert(error: error)
                return
            }
            
            guard let feature = result?.first?.geoElements.first as? AGSArcGISFeature else { return }

            self.addStartElementOrBarrier(for: feature, at: mapPoint)
        }
    }
    
    /// Based on the selection mode, the tapped utility element is added either to the starting locations or barriers for the trace parameters.
    /// An appropriate graphic is created at the tapped location to mark the element as either a starting location or barrier.
    ///
    /// - Parameters:
    ///   - feature: The geoelement retrieved as an AGSArcGISFeature.
    ///   - location: The AGSPoint used to identify utility elements in the utility network.
    private func addStartElementOrBarrier(for feature: AGSArcGISFeature, at location: AGSPoint) {
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
            let networkSource = utilityNetwork.definition.networkSource(withName: featureTable.tableName) else {
                self.setStatus(message: "Could not identify location.")
                return
        }
        
        switch networkSource.sourceType {
        case .junction:
            // If the user tapped on a junction, get the asset's terminal(s).
            if let assetGroupField = featureTable.field(forName: featureTable.subtypeField),
                let assetGroupCode = feature.attributes[assetGroupField.name] as? Int,
                let assetGroup = networkSource.assetGroups.first(where: { $0.code == assetGroupCode }),
                let assetTypeField = featureTable.field(forName: "ASSETTYPE"),
                let assetTypeCode = feature.attributes[assetTypeField.name] as? Int,
                let assetType = assetGroup.assetTypes.first(where: { $0.code == assetTypeCode }),
                let terminals = assetType.terminalConfiguration?.terminals {
                selectTerminal(from: terminals, at: feature.geometry as? AGSPoint ?? location) { [weak self, currentMode] terminal in
                    guard let self = self,
                        let element = self.utilityNetwork.createElement(with: feature, terminal: terminal),
                        let location = feature.geometry as? AGSPoint else { return }
                    
                    self.add(element: element, for: location, mode: currentMode)
                    self.setStatus(message: "terminal: \(terminal.name)")
                }
            }
        case .edge:
            // If the user tapped on an edge, determine how far along that edge.
            if let geometry = feature.geometry,
                let line = AGSGeometryEngine.geometryByRemovingZ(from: geometry) as? AGSPolyline,
                let element = utilityNetwork.createElement(with: feature, terminal: nil) {
                element.fractionAlongEdge = AGSGeometryEngine.fraction(alongLine: line, to: location, tolerance: -1)
                
                add(element: element, for: location, mode: currentMode)
                setStatus(message: String(format: "fractionAlongEdge: %.3f", element.fractionAlongEdge))
            }
        @unknown default:
            presentAlert(message: "Unexpected Network Source type!")
        }
    }
    
    private func add(element: AGSUtilityElement, for location: AGSPoint, mode: InteractionMode) {
        switch mode {
        case .addingStartLocation:
            traceParameters.startingLocations.append(element)
        case .addingBarriers:
            traceParameters.barriers.append(element)
        }
        
        setUIState()
        
        let traceLocationGraphic = AGSGraphic(geometry: location, symbol: nil, attributes: ["TraceLocationType": mode.traceLocationType])
        parametersOverlay.graphics.add(traceLocationGraphic)
    }
    
    // MARK: Perform Trace
    @IBAction func traceNetwork(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Running \(traceType.0) trace…")
        let parameters = AGSUtilityTraceParameters(traceType: traceType.1, startingLocations: traceParameters.startingLocations)
        traceParameters.barriers.forEach { barrier in
            parameters.barriers.append(barrier)
        }
        // Set the trace configuration using the tier from the utility domain network.
        parameters.traceConfiguration = utilityTier?.traceConfiguration
        
        utilityNetwork.trace(with: parameters) { [weak self] (traceResult, error) in
            if let error = error {
                self?.setStatus(message: "Trace failed.")
                SVProgressHUD.dismiss()
                self?.presentAlert(error: error)
                return
            }

            guard let self = self else { return }
            
            guard let elementTraceResult = traceResult?.first as? AGSUtilityElementTraceResult,
                !elementTraceResult.elements.isEmpty else {
                    self.setStatus(message: "Trace completed with no output.")
                    SVProgressHUD.dismiss()
                    return
            }
            
            self.clearSelection()

            SVProgressHUD.show(withStatus: "Trace completed. Selecting features…")

            let groupedElements = Dictionary(grouping: elementTraceResult.elements) { $0.networkSource.name }
            
            let selectionGroup = DispatchGroup()

            for (networkName, elements) in groupedElements {
                guard let layer = self.map.operationalLayers.first(where: { ($0 as? AGSFeatureLayer)?.featureTable?.tableName == networkName }) as? AGSFeatureLayer else { continue }

                selectionGroup.enter()
                print("Requesting features for \(networkName)")
                self.utilityNetwork.features(for: elements) { [layer, networkName] (features, error) in
                    defer {
                        print("Result From: \(networkName)")
                        selectionGroup.leave()
                    }
                    
                    if let error = error {
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
    
    func clearSelection() {
        map.operationalLayers.lazy
            .compactMap { $0 as? AGSFeatureLayer }
            .forEach { $0.clearSelection() }
    }
    
    // MARK: Terminal Selection UI
    /// Popup an action sheet to select one from multiple terminals, or return if there is only one.
    ///
    /// - Parameters:
    ///   - terminals: A list of terminals.
    ///   - mapPoint: The location tapped on the map.
    ///   - completion: Completion clousre to pass the selected terminal.
    private func selectTerminal(from terminals: [AGSUtilityTerminal], at mapPoint: AGSPoint, completion: @escaping (AGSUtilityTerminal) -> Void) {
        if terminals.count > 1 {
            // Show a terminal picker
            let terminalPicker = UIAlertController(title: "Select a terminal", message: nil, preferredStyle: .actionSheet)
            
            for terminal in terminals {
                let action = UIAlertAction(title: terminal.name, style: .default) { [terminal] _ in
                    completion(terminal)
                }
                
                terminalPicker.addAction(action)
            }
            
            terminalPicker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(terminalPicker, animated: true, completion: nil)
            
            if let popoverController = terminalPicker.popoverPresentationController {
                // If we're presenting in a split view controller (e.g. on an iPad),
                // provide positioning information for the alert view.
                popoverController.sourceView = mapView
                let tapPoint = mapView.location(toScreen: mapPoint)
                popoverController.sourceRect = CGRect(origin: tapPoint, size: .zero)
            }
        } else if let terminal = terminals.first {
            completion(terminal)
        }
    }

    // MARK: Interaction Mode
    private enum InteractionMode: Int {
        case addingStartLocation = 0
        case addingBarriers = 1
        
        var traceLocationType: String {
            switch self {
            case .addingStartLocation:
                return "starting point"
            case .addingBarriers:
                return "barrier"
            }
        }
        
        func toString() -> String {
            switch self {
            case .addingStartLocation:
                return "Start Location"
            case .addingBarriers:
                return "Barrier"
            }
        }
    }
    
    private var currentMode: InteractionMode = .addingStartLocation {
        didSet {
            setInstructionMessage()
        }
    }
    
    @IBAction func setMode(_ modePickerControl: UISegmentedControl) {
        if let mode = InteractionMode(rawValue: modePickerControl.selectedSegmentIndex) {
            currentMode = mode
        }
    }
    
    // MARK: Set trace type
    @IBAction func setTraceType(_ sender: Any) {
        let alertController = UIAlertController(title: "Select trace type", message: nil, preferredStyle: .actionSheet)
        let types = [
            ("Connected", AGSUtilityTraceType.connected),
            ("Subnetwork", AGSUtilityTraceType.subnetwork),
            ("Upstream", AGSUtilityTraceType.upstream),
            ("Downstream", AGSUtilityTraceType.downstream)
        ]
        types.forEach { type in
            let action = UIAlertAction(title: type.0, style: .default) { [unowned self] _ in
                self.traceType = type
                self.setStatus(message: "Trace type \(type.0) selected.")
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = typeButton
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Reset trace
    @IBAction func reset(_ sender: Any) {
        clearSelection()
        traceParameters.startingLocations.removeAll()
        traceParameters.barriers.removeAll()
        parametersOverlay.graphics.removeAllObjects()
        traceType = ("Connected", .connected)
        setInstructionMessage()
    }

    // MARK: UI and Feedback
    private func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func setUIState() {
        let utilityNetworkIsReady = utilityNetwork.loadStatus == .loaded
        modeControl.isEnabled = utilityNetworkIsReady
        modeLabel.isEnabled = modeControl.isEnabled
        
        let canTrace = utilityNetworkIsReady && !traceParameters.startingLocations.isEmpty
        traceNetworkButton.isEnabled = canTrace
        resetButton.isEnabled = traceNetworkButton.isEnabled
    }
    
    func setInstructionMessage() {
        setStatus(message: "Tap on the map to add a \(currentMode.toString())")
    }
}
