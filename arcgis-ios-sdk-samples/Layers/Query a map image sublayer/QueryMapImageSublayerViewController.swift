//
// Copyright © 2018 Esri.
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
//

import UIKit
import ArcGIS

class QueryMapImageSublayerViewController: UIViewController {
    /// The map displayed in the map view.
    let map: AGSMap
    let graphicsOverlay: AGSGraphicsOverlay
    
    required init?(coder: NSCoder) {
        map = AGSMap(basemap: .streetsVector())
        
        // Set the initial viewpoint.
        let center = AGSPoint(x: -12716000.00, y: 4170400.00, spatialReference: .webMercator())
        map.initialViewpoint = AGSViewpoint(center: center, scale: 6000000)
        
        // Create an image layer and add it to the map.
        let mapImageLayer = AGSArcGISMapImageLayer(url: .unitedStatesMapService)
        map.operationalLayers.add(mapImageLayer)
        
        // Create the graphics overlay.
        graphicsOverlay = AGSGraphicsOverlay()
        
        super.init(coder: coder)
        
        // Begin loading the image layer.
        mapImageLayer.load { [weak self, unowned layer = mapImageLayer] (error) in
            if let error = error {
                self?.mapImageLayer(layer, didFailToLoadWith: error)
            } else {
                self?.mapImageLayerDidLoad(layer)
            }
        }
    }
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var populationTextField: UITextField!
    @IBOutlet weak var queryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["QueryMapImageSublayerViewController"]
        
        // Assign the map to the map view.
        mapView.map = map
        
        // Add the graphics overlay to the map view.
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        enableControlsIfNeeded()
    }
    
    enum SublayerKey: Int {
        case cities = 0
        case states = 2
        case counties = 3
        
        /// A set of all values of this type.
        static var allCases: Set<SublayerKey> {
            return [.cities, .states, .counties]
        }
    }
    
    /// The sublayers of the map image layer.
    var mapImageLayerSublayers = [SublayerKey: AGSArcGISMapImageSublayer]()
    
    /// Called in response to the map image layer loading successfully.
    func mapImageLayerDidLoad(_ layer: AGSArcGISMapImageLayer) {
        for key in SublayerKey.allCases {
            guard let sublayer = layer.mapImageSublayers[key.rawValue] as? AGSArcGISMapImageSublayer else { continue }
            mapImageLayerSublayers[key] = sublayer
            sublayer.load { [weak self] (error) in
                if let error = error {
                    print("Error loading sublayer \(sublayer.name): \(error)")
                } else {
                    self?.enableControlsIfNeeded()
                }
            }
        }
    }
    
    /// Called in response to the map image layer failing to load. Presents an
    /// alert announcing the failure.
    ///
    /// - Parameter error: The error that caused loading to fail.
    func mapImageLayer(_ layer: AGSArcGISMapImageLayer, didFailToLoadWith error: Error) {
        let okayAction = UIAlertAction(title: "OK", style: .default)
        let alertController = UIAlertController(title: nil, message: "Failed to load ArcGIS map image layer \(layer.name).", preferredStyle: .alert)
        alertController.addAction(okayAction)
        alertController.preferredAction = okayAction
        present(alertController, animated: true)
    }
    
    /// Enables the text field and button if they can be enabled and haven't
    /// been already.
    func enableControlsIfNeeded() {
        guard isViewLoaded,
            !populationTextField.isEnabled,
            mapImageLayerSublayers.contains(where: { $0.value.loadStatus == .loaded }) else {
                return
        }
        populationTextField.isEnabled = true
        populationTextField.becomeFirstResponder()
        queryButton.isEnabled = true
    }
    
    /// The number formatter used to convert the user input string to a number.
    let numberFormatter = NumberFormatter()
    
    @IBAction func query(_ sender: Any) {
        populationTextField.resignFirstResponder()
        let trimmedText = populationTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if let value = numberFormatter.number(from: trimmedText) {
            populationValue = value.intValue
        } else if trimmedText.isEmpty {
            populationValue = nil
        } else {
            let okayAction = UIAlertAction(title: "OK", style: .default)
            let alertController = UIAlertController(title: nil, message: "The population value must be numeric.", preferredStyle: .alert)
            alertController.addAction(okayAction)
            alertController.preferredAction = okayAction
            present(alertController, animated: true)
        }
    }
    
    /// The population value provided by the user.
    var populationValue: Int? {
        didSet {
            populationValueDidChange()
        }
    }
    
    /// Called in response to the population value changing.
    func populationValueDidChange() {
        graphicsOverlay.graphics.removeAllObjects()
        
        guard let populationValue = populationValue else { return }
        
        let populationQuery = AGSQueryParameters()
        populationQuery.whereClause = "POP2000 > \(populationValue)"
        populationQuery.geometry = mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry
        
        for (_, sublayer) in mapImageLayerSublayers {
            guard let table = sublayer.table else { continue }
            table.queryFeatures(with: populationQuery) { [weak self] (result, error) in
                if let result = result {
                    self?.featureTable(table, featureQueryDidSucceedWith: result)
                } else if let error = error {
                    self?.featureTable(table, featureQueryDidFailWith: error)
                }
            }
        }
    }
    
    /// Called when a feature query of a feature table finishes successfully.
    ///
    /// - Parameters:
    ///   - featureTable: The feature table that was queried.
    ///   - result: The feature query result.
    func featureTable(_ featureTable: AGSFeatureTable, featureQueryDidSucceedWith result: AGSFeatureQueryResult) {
        let symbol = makeSymbol(featureTable: featureTable)
        let graphics: [AGSGraphic] = result.featureEnumerator().map {
            AGSGraphic(geometry: ($0 as! AGSFeature).geometry, symbol: symbol, attributes: nil)
        }
        graphicsOverlay.graphics.addObjects(from: graphics)
    }
    
    /// Called when a feature query of a feature table is unsuccessful.
    ///
    /// - Parameters:
    ///   - featureTable: The feature table that was queried.
    ///   - error: The error that caused the query to fail.
    func featureTable(_ featureTable: AGSFeatureTable, featureQueryDidFailWith error: Error) {
        print("\(featureTable.tableName) feature query failed: \(error)")
    }
    
    /// Creates a symbol for features of the given feature table.
    ///
    /// - Parameter featureTable: A feature table.
    /// - Returns: An `AGSSymbol` object.
    func makeSymbol(featureTable: AGSFeatureTable) -> AGSSymbol? {
        switch featureTable {
        case mapImageLayerSublayers[.cities]?.table:
            return AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 16)
        case mapImageLayerSublayers[.states]?.table:
            let outline = AGSSimpleLineSymbol(style: .solid, color: #colorLiteral(red: 0, green: 0.5450980392, blue: 0.5450980392, alpha: 1), width: 6)
            return AGSSimpleFillSymbol(style: .null, color: .cyan, outline: outline)
        case mapImageLayerSublayers[.counties]?.table:
            let outline = AGSSimpleLineSymbol(style: .dash, color: .cyan, width: 2)
            return AGSSimpleFillSymbol(style: .diagonalCross, color: .cyan, outline: outline)
        default:
            return nil
        }
    }
}

extension QueryMapImageSublayerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        query(textField)
        return false
    }
}
