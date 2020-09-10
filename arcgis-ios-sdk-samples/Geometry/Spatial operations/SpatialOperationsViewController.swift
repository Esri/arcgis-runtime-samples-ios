// Copyright 2017 Esri.
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

class SpatialOperationsViewController: UIViewController {
    // MARK: Storyboard view and properties
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with basemap.
            mapView.map = AGSMap(basemap: .topographic())
            // Add the graphics overlay with two polygon graphics and the result graphic to map view.
            mapView.graphicsOverlays.add(makeGraphicsOverlay())
            // Set initial viewpoint.
            let center = AGSPoint(x: -13453, y: 6710127, spatialReference: .webMercator())
            mapView.setViewpointCenter(center, scale: 30000, completion: nil)
        }
    }
    
    /// The resulting graphic for the spatial operation.
    private var resultGraphic: AGSGraphic!
    
    private let polygon1: AGSGeometry = {
        // Create the polygon 1.
        let polygon = AGSPolygonBuilder(spatialReference: .webMercator())
        polygon.addPointWith(x: -13960, y: 6709400)
        polygon.addPointWith(x: -14660, y: 6710000)
        polygon.addPointWith(x: -13760, y: 6710730)
        polygon.addPointWith(x: -13300, y: 6710500)
        polygon.addPointWith(x: -13160, y: 6710100)
        return polygon.toGeometry()
    }()
    
    private let polygon2: AGSGeometry = {
        // The outer ring of polygon 2.
        let outerRing = AGSMutablePart(spatialReference: .webMercator())
        outerRing.addPointWith(x: -13060, y: 6711030)
        outerRing.addPointWith(x: -12160, y: 6710730)
        outerRing.addPointWith(x: -13160, y: 6709700)
        outerRing.addPointWith(x: -14560, y: 6710730)
        outerRing.addPointWith(x: -13060, y: 6711030)
        
        // The inner ring of polygon 2.
        let innerRing = AGSMutablePart(spatialReference: .webMercator())
        innerRing.addPointWith(x: -13060, y: 6710910)
        innerRing.addPointWith(x: -14160, y: 6710630)
        innerRing.addPointWith(x: -13160, y: 6709900)
        innerRing.addPointWith(x: -12450, y: 6710660)
        innerRing.addPointWith(x: -13060, y: 6710910)
        
        // Create polygon 2.
        let polygon = AGSPolygonBuilder(spatialReference: .webMercator())
        polygon.parts.add(outerRing)
        polygon.parts.add(innerRing)
        return polygon.toGeometry()
    }()
    
    /// An enum of spatial operations.
    private enum SpatialOperation: CaseIterable {
        case none, union, difference, symmetricDifference, intersection
        /// Human readable label strings for each spatial operation.
        var label: String {
            switch self {
            case .none: return "None"
            case .union: return "Union"
            case .difference: return "Difference"
            case .symmetricDifference: return "Symmetric Difference"
            case .intersection: return "Intersection"
            }
        }
    }
    /// The selected operation.
    private var selectedOperation = SpatialOperation.none
    
    // MARK: Methods
    
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        // A black line symbol for borders of the graphics.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        // The blue fill symbol of polygon 1.
        let fillSymbol1 = AGSSimpleFillSymbol(style: .solid, color: .blue, outline: lineSymbol)
        // The graphic of polygon 1.
        let polygon1Graphic = AGSGraphic(geometry: polygon1, symbol: fillSymbol1)
        // The green fill symbol of polygon 2.
        let fillSymbol2 = AGSSimpleFillSymbol(style: .solid, color: .green, outline: lineSymbol)
        // The graphic of polygon 2.
        let polygon2Graphic = AGSGraphic(geometry: polygon2, symbol: fillSymbol2)
        
        // Using red fill symbol with black border for result graphic.
        let symbol = AGSSimpleFillSymbol(style: .solid, color: .red, outline: lineSymbol)
        let graphic = AGSGraphic(geometry: nil, symbol: symbol)
        resultGraphic = graphic
        
        // An overlay to display polygon graphics.
        let graphicsOverlay = AGSGraphicsOverlay()
        
        // Add graphics to graphics overlay.
        graphicsOverlay.graphics.addObjects(from: [polygon1Graphic, polygon2Graphic, graphic])
        return graphicsOverlay
    }
    
    private func performOperation(_ operation: SpatialOperation) {
        let resultGeometry: AGSGeometry?
        switch operation {
        case .none:
            resultGeometry = nil
        case .union:
            resultGeometry = AGSGeometryEngine.union(ofGeometry1: polygon1, geometry2: polygon2)!
        case .difference:
            resultGeometry = AGSGeometryEngine.difference(ofGeometry1: polygon1, geometry2: polygon2)!
        case .symmetricDifference:
            resultGeometry = AGSGeometryEngine.symmetricDifference(ofGeometry1: polygon1, geometry2: polygon2)!
        case .intersection:
            resultGeometry = AGSGeometryEngine.intersection(ofGeometry1: polygon1, geometry2: polygon2)!
        }
        // Update the geometry.
        resultGraphic.geometry = resultGeometry
    }
    
    @IBAction func chooseOperationBarButtonTapped(_ sender: UIBarButtonItem) {
        let selectedIndex = SpatialOperation.allCases.firstIndex(where: { $0 == selectedOperation })
        
        let controller = OptionsTableViewController(labels: SpatialOperation.allCases.map { $0.label }, selectedIndex: selectedIndex) { [weak self] newIndex in
            guard let self = self else { return }
            let newOperation = SpatialOperation.allCases[newIndex]
            if self.selectedOperation != newOperation {
                self.selectedOperation = newOperation
                // Perform the spatial operation.
                self.performOperation(self.selectedOperation)
            }
        }
        
        // Configure the options controller as a popover.
        controller.modalPresentationStyle = .popover
        controller.presentationController?.delegate = self
        controller.preferredContentSize = CGSize(width: 300, height: CGFloat(SpatialOperation.allCases.count) * 44)
        controller.popoverPresentationController?.barButtonItem = sender
        
        // Show the popover.
        present(controller, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["SpatialOperationsViewController"]
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SpatialOperationsViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Show presented controller as a popover even on small displays.
        return .none
    }
}
