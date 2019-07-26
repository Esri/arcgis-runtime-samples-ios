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

class ConnectedTraceViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView!

    @IBOutlet weak var traceNetworkButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var modeControl: UISegmentedControl!
    @IBOutlet weak var statusLabel: UILabel!
    
    private let featureServiceURL = URL(string: "")!
    private let layerIds = [4, 3, 5, 0]

    private let map: AGSMap
    private let utilityNetwork: AGSUtilityNetwork
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
        map.operationalLayers.addObjects(from: layerIds.map({
            let featureTable = AGSServiceFeatureTable(url: featureServiceURL.appendingPathComponent("\($0)"))
            return AGSFeatureLayer(featureTable: featureTable)
        }))
    }
    
    // MARK: Initialize user interface
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the UI
        setUIState()

        // Set up the map view
        mapView.map = map
        mapView.graphicsOverlays.add(parametersOverlay)
        mapView.touchDelegate = self
        
        // Load the Utility Network to be ready for us to run a trace against it.
        setStatus(message: "Loading Utility Network…")
        utilityNetwork.load { [weak self] error in
            if let error = error {
                self?.setStatus(message: "Loading Utility Network Failed")
                self?.presentAlert(error: error)
                return
            }
            
            // Update the UI to allow network traces to be run.
            self?.setUIState()
            
            self?.setInstructionMessage()
        }
    }
    
    // MARK: Set trace start points and barriers
    var identifyAction: AGSCancelable?
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let identifyAction = identifyAction {
            identifyAction.cancel()
        }

        setStatus(message: "Identifying trace locations…")
        identifyAction = mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [utilityNetwork, currentMode, weak self] (result, error) in
            if let error = error {
                self?.setStatus(message: "Error identifying trace locations.")
                self?.presentAlert(error: error)
                return
            }
            
            guard let self = self else { return }
            
            guard let feature = result?.first?.geoElements.first as? AGSArcGISFeature,
                let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
                let networkSource = utilityNetwork.definition.networkSource(withName: featureTable.tableName) else {
                self.setStatus(message: "Could not identify location.")
                return
            }
            
            switch networkSource.sourceType {
            case .junction:
                // If the user tapped on a junction, get the asset's terminal(s).
                let assetGroupFieldName = !featureTable.subtypeField.isEmpty ? featureTable.subtypeField : "ASSETGROUP"
                if let assetGroupCode = feature.attributes[assetGroupFieldName] as? Int,
                    let assetGroup = networkSource.assetGroups.first(where: { $0.code == assetGroupCode }),
                    let assetTypeCode = feature.attributes["ASSETTYPE"] as? Int,
                    let assetType = assetGroup.assetTypes.first(where: { $0.code == assetTypeCode }),
                    let terminals = assetType.terminalConfiguration?.terminals {
                    self.selectTerminal(from: terminals) { [feature] terminal in
                        guard let element = utilityNetwork.createElement(with: feature, terminal: terminal),
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
                    element.fractionAlongEdge = AGSGeometryEngine.fraction(alongLine: line, to: mapPoint, tolerance: -1)
                    
                    self.add(element: element, for: mapPoint, mode: currentMode)
                    self.setStatus(message: "fractionAlongEdge: \(element.fractionAlongEdge)")
                }
            @unknown default:
                self.presentAlert(message: "Unexpected Network Source Type!")
            }
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
        self.parametersOverlay.graphics.add(traceLocationGraphic)
    }
    
    // MARK: Perform Trace
    @IBAction func traceNetwork(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Running connected trace…")
        let parameters = traceParameters
        
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

            SVProgressHUD.show(withStatus: "Trace Completed. Selecting features…")

            let groupedElements = Dictionary(grouping: elementTraceResult.elements, by: { $0.networkSource.name })
            
            let selectionGroup = DispatchGroup()

            for (networkName, elements) in groupedElements {
                guard let layer = self.map.operationalLayers.first(where: { ($0 as? AGSFeatureLayer)?.featureTable?.tableName == networkName }) as? AGSFeatureLayer else { continue }

                selectionGroup.enter()
                print("Requesting features for \(networkName)")
                self.utilityNetwork.features(for: elements, completion: { [layer, networkName] (features, error) in
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
                })
            }
            
            selectionGroup.notify(queue: .main, execute: {
                self.setStatus(message: "Trace completed.")
                SVProgressHUD.dismiss()
            })
        }
    }
    
    func clearSelection() {
        map.operationalLayers.lazy.compactMap({ $0 as? AGSFeatureLayer }).forEach({ $0.clearSelection() })
    }
    
    // MARK: Terminal Selection UI
    private func selectTerminal(from terminals: [AGSUtilityTerminal], completion: @escaping (AGSUtilityTerminal) -> Void) {
        if terminals.count > 1 {
            // Show a terminal picker
            let terminalPicker = UIAlertController(title: "Select a terminal", message: nil, preferredStyle: .actionSheet)
            
            for terminal in terminals {
                let action = UIAlertAction(title: terminal.name, style: .default, handler: { [terminal] _ in
                    completion(terminal)
                })
                
                terminalPicker.addAction(action)
            }
            
            if !terminalPicker.actions.isEmpty {
                terminalPicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(terminalPicker, animated: true, completion: nil)
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
                return barrierAttributeValue
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
    
    // MARK: Reset trace
    @IBAction func reset(_ sender: Any) {
        clearSelection()
        traceParameters.startingLocations.removeAll()
        traceParameters.barriers.removeAll()
        parametersOverlay.graphics.removeAllObjects()
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
