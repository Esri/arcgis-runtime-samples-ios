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
    /// A simple marker symbol to display where the user tapped/clicked on the map.
    static let markerSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
    
    /// A simple line symbol for the outline of the convex hull graphic(s).
    static let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 4)
    
    /// A simple fill symbol for the convex hull graphic(s) - a hollow polygon with a thick red outline.
    static let fillSymbol = AGSSimpleFillSymbol(style: .null, color: .red, outline: lineSymbol)
    
    /// The graphics overlay for the convex hull.
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// The graphic for the convex hull - comprised of either a point, a polyline or a polygon shape.
    let convexHullGraphic = AGSGraphic(geometry: nil, symbol: nil, attributes: ["Type": "Hull"])
    
    /// List of geometry values (MapPoints in this case) that will be used by the AGSGeometryEngine.convexHull operation.
    var inputPointArray: [AGSPoint] = []
    
    /// The bar button item that initiates the create convex hull operation.
    @IBOutlet weak var creatConvexHullButtonItem: UIBarButtonItem!
    
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
        guard let convexHullGeometry = AGSGeometryEngine.convexHull(for: AGSMultipoint(points: inputPointArray)) else {
            // Display the error as an alert if there is a problem with AGSGeometryEngine.convexHull operation.
            let alertController = UIAlertController(title: nil, message: "Geometry Engine Failed!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
            return
        }
        // Change the symbol depending on the returned geometry type of the convex hull.
        switch convexHullGeometry.geometryType {
        case .point:
            convexHullGraphic.symbol = ConvexHullViewController.markerSymbol
        case .polyline:
            convexHullGraphic.symbol = ConvexHullViewController.lineSymbol
        case .polygon:
            convexHullGraphic.symbol = ConvexHullViewController.fillSymbol
        default:
            convexHullGraphic.symbol = ConvexHullViewController.fillSymbol
        }
        convexHullGraphic.geometry = convexHullGeometry
        creatConvexHullButtonItem.isEnabled = false
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        // Clear the existing points and graphics.
        inputPointArray.removeAll()
        graphicsOverlay.graphics.removeAllObjects()
        // Reset the graphic for the convex hull and add it back to the to the graphics overlay.
        convexHullGraphic.geometry = nil
        graphicsOverlay.graphics.add(convexHullGraphic)
        // Reset button states.
        resetButtonItem.isEnabled = false
        creatConvexHullButtonItem.isEnabled = false
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphicsOverlay.graphics.add(convexHullGraphic)
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ConvexHullViewController"]
    }
}

extension ConvexHullViewController: AGSGeoViewTouchDelegate {
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Add the map point to the array that will be used by the AGSGeometryEngine.convexHull operation.
        inputPointArray.append(mapPoint)
        if !inputPointArray.isEmpty {
            resetButtonItem.isEnabled = true
            creatConvexHullButtonItem.isEnabled = true
        }
        // Create a new graphic for the spot where the user tapped on the map using the simple marker symbol.
        let userTappedGraphic = AGSGraphic(geometry: mapPoint, symbol: ConvexHullViewController.markerSymbol, attributes: ["Type": "Point"])
        graphicsOverlay.graphics.add(userTappedGraphic)
    }
}
