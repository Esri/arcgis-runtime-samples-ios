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
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(graphicsOverlay)
            //set touch delegate on map view as self
            mapView.touchDelegate = self
        }
    }
    /// The bar button item that initiates the create convex hull operation.
    @IBOutlet weak var creatConvexHullButtonItem: UIBarButtonItem!
    /// The bar button item that removes the convex hull.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    
    /// The graphics overlay for the convex hull.
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// List of geometry values (MapPoints in this case) that will be used by the GeometryEngine.ConvexHull operation.
    var inputPointArray: [AGSPoint] = []
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .topographic())
        return map
    }
    
    /// Called in response to the Create convex hull button being tapped.
    @IBAction func createConvexHull() {
        let inputMultipoint = AGSMultipoint(points: inputPointArray)
        let convexHullGeometry = AGSGeometryEngine.convexHull(for: inputMultipoint)
        let convexHullSimpleLineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 4)
        let convexHullSimpleFillSymbol = AGSSimpleFillSymbol(style: .null, color: .red, outline: convexHullSimpleLineSymbol)
        let convexHullGraphic = AGSGraphic(geometry: convexHullGeometry, symbol: convexHullSimpleFillSymbol, attributes: ["Type": "Hull"])
        
        for g in graphicsOverlay.graphics {
            if (g as! AGSGraphic).attributes["Type"] as? String == "Hull" {
                graphicsOverlay.graphics.remove(g)
            }
        }
        
        graphicsOverlay.graphics.add(convexHullGraphic)
        creatConvexHullButtonItem.isEnabled = false
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        inputPointArray.removeAll()
        graphicsOverlay.graphics.removeAllObjects()
        resetButtonItem.isEnabled = false
        creatConvexHullButtonItem.isEnabled = false
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
        inputPointArray.append(mapPoint)
        if !inputPointArray.isEmpty {
            resetButtonItem.isEnabled = true
            creatConvexHullButtonItem.isEnabled = true
        }
        // Create a simple marker symbol to display where the user tapped/clicked on the map. The marker symbol will be a solid, red circle.
        let symbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        let userTappedGraphic = AGSGraphic(geometry: mapPoint, symbol: symbol, attributes: ["Type": "Point"])
        userTappedGraphic.zIndex = 1
        self.graphicsOverlay.graphics.add(userTappedGraphic)
    }
}
