// Copyright © 2022 Esri.
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

class ApplyUniqueValuesAlternateSymbolsViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Set the map and its initial viewpoint.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13632095.660131, y: 4545009.846004, spatialReference: .webMercator()), scale: 2500))
        }
    }
    
    @IBOutlet var currentScaleLabel: UILabel!
    @IBOutlet var resetViewpointBarButtonItem: UIBarButtonItem!
    
    /// Response to the bar button item being tapped.
    @IBAction func resetViewpointTapped(_ button: UIBarButtonItem) {
        // Create the initial viewpoint.
        let viewpoint = AGSViewpoint(center: AGSPoint(x: -13631205.660131, y: 4546829.846004, spatialReference: .webMercator()), scale: 7500)
        // Set the viewpoint with animation.
        mapView.setViewpoint(viewpoint, duration: 5, curve: AGSAnimationCurve.easeInOutSine) { (finishedWithoutInterruption) in
            if finishedWithoutInterruption {
                self.mapView.setViewpoint(viewpoint, duration: 5, curve: .easeInOutSine)
            }
        }
    }
    
    /// The feature service URL.
    static let featureServiceURL = URL(string: String("https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"))!
    /// The feature layer set in San Francisco, CA.
    let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url: featureServiceURL))
    
    /// The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    /// Creates the unique values renderer for the feature layer.
    func createUniqueValuesRenderer() {
        // Create the default symbol.
        let symbol = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 30)
        // Convert the symbol to a multi layer symbol.
        let multiLayerSymbol = symbol.toMultilayerSymbol()
        multiLayerSymbol.referenceProperties = AGSSymbolReferenceProperties(minScale: 5000, maxScale: 0)
        // Create alternate symbols for the unique value.
        let alternateSymbols = createAlternateSymbols()
        // Create a unique value with alternate symbols.
        let uniqueValue = AGSUniqueValue(description: "unique values based on request type", label: "unique value", symbol: multiLayerSymbol, values: ["Damaged Property"], alternateSymbols: alternateSymbols)
        // Create a unique values renderer.
        let uniqueValueRenderer = AGSUniqueValueRenderer()
        // Create and append the unique value.
        uniqueValueRenderer.uniqueValues.append(uniqueValue)
        // Set the field name.
        uniqueValueRenderer.fieldNames = ["req_type"]
        // Create and set the default symbol.
        let defaultSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .purple, size: 15)
        uniqueValueRenderer.defaultSymbol = defaultSymbol.toMultilayerSymbol()
        
        // Set the unique value renderer on the feature layer.
        featureLayer.renderer = uniqueValueRenderer
    }
    
    /// Create alternate symbols for the unique value renderer.
    func createAlternateSymbols() -> [AGSMultilayerPointSymbol] {
        // Create the alternate symbol for the mid range scale.
        let alternateSymbol = AGSSimpleMarkerSymbol(style: .square, color: .blue, size: 30)
        // Convert the symbol to a multilayer symbol.
        let alternateSymbolMultilayer1 = alternateSymbol.toMultilayerSymbol()
        // Set the reference properties.
        alternateSymbolMultilayer1.referenceProperties = AGSSymbolReferenceProperties(minScale: 10000, maxScale: 5000)
        
        // Create the alternate symbol for the high range scale.
        let alternateSymbol2 = AGSSimpleMarkerSymbol(style: .diamond, color: .yellow, size: 30)
        // Convert the symbol to a multilayer symbol.
        let alternateSymbolMultilayer2 = alternateSymbol2.toMultilayerSymbol()
        // Set the reference properties.
        alternateSymbolMultilayer2.referenceProperties = AGSSymbolReferenceProperties(minScale: 20000, maxScale: 10000)
        // Return both alternate symbols.
        return [alternateSymbolMultilayer1, alternateSymbolMultilayer2]
    }
    
    /// Update the label to display the current scale.
    func changeScaleLabel() {
        let mapScale = scaleFormatter.string(from: mapView.mapScale as NSNumber)!
        currentScaleLabel.text = "Current scale: 1:\(mapScale)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add a handler to update the current label.
        mapView.viewpointChangedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.changeScaleLabel()
            }
        }
        createUniqueValuesRenderer()
        mapView.map?.operationalLayers.add(featureLayer)
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ApplyUniqueValuesAlternateSymbolsViewController"]
    }
}
