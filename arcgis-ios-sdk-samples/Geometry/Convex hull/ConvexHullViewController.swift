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

class ConvexHullViewController: UIViewController {
    /// The graphics overlay for the convex hull.
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// A simple marker symbol to display where the user tapped/clicked on the map.
    let markerSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
    
    /// A simple line symbol for the outline of the convex hull graphic(s).
    let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 4)
    
    /// A simple fill symbol for the convex hull graphic(s) - a hollow polygon with a thick red outline.
    lazy var fillSymbol = AGSSimpleFillSymbol(style: .null, color: .red, outline: lineSymbol)
    
    /// List of geometry values (MapPoints in this case) that will be used by the AGSGeometryEngine.convexHull operation.
    var inputPoints: [AGSPoint] = []
    
    /// The bar button item that initiates the create convex hull operation.
    @IBOutlet weak var creatButtonItem: UIBarButtonItem!
    
    /// The bar button item that removes the convex hull as well as the MapPoints.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(graphicsOverlay)
            mapView.touchDelegate = self
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .topographic())
        return map
    }
    
    /// Called in response to the Create convex hull button being tapped.
    @IBAction func createConvexHull() {
        if let convexHullGeometry = AGSGeometryEngine.convexHull(for: AGSMultipoint(points: inputPoints)) {
            // Remove any existing convex hull graphics from the overlay.
            for g in graphicsOverlay.graphics.reversed() {
                if (g as! AGSGraphic).attributes["Type"] as! String == "Hull" {
                    graphicsOverlay.graphics.remove(g)
                }
            }
            // Change the symbol depending on the returned geometry type of the convex hull.
            let symbol: AGSSymbol
            switch convexHullGeometry.geometryType {
            case .point:
                symbol = markerSymbol
            case .polyline:
                symbol = lineSymbol
            default:
                symbol = fillSymbol
            }
            // Create the graphic for the convex hull and add it to the graphics overlay.
            let convexHullGraphic = AGSGraphic(geometry: convexHullGeometry, symbol: symbol, attributes: ["Type": "Hull"])
            graphicsOverlay.graphics.add(convexHullGraphic)
            creatButtonItem.isEnabled = false
        } else {
            // Display the error as an alert if there is a problem with AGSGeometryEngine.convexHull operation.
            let alertController = UIAlertController(title: nil, message: "Geometry Engine Failed!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        // Clear the existing points and graphics.
        inputPoints.removeAll()
        graphicsOverlay.graphics.removeAllObjects()
        // Reset button states.
        resetButtonItem.isEnabled = false
        creatButtonItem.isEnabled = false
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ConvexHullViewController"]
    }
}

extension ConvexHullViewController: AGSGeoViewTouchDelegate {
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Add the map point to the array that will be used by the AGSGeometryEngine.convexHull operation.
        inputPoints.append(mapPoint)
        if !inputPoints.isEmpty {
            resetButtonItem.isEnabled = true
            creatButtonItem.isEnabled = true
        }
        // Create a new graphic for the spot where the user tapped on the map using the simple marker symbol.
        let userTappedGraphic = AGSGraphic(geometry: mapPoint, symbol: markerSymbol, attributes: ["Type": "Point"])
        graphicsOverlay.graphics.add(userTappedGraphic)
    }
}
