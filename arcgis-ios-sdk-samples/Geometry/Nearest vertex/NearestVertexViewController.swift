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

class NearestVertexViewController: UIViewController {
    /// Create the graphics and symbology for the tapped point, the nearest vertex and the nearest coordinate.
    static let tappedLocationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .orange, size: 15)
    static let nearestCoordinateSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .red, size: 10)
    static let nearestVertexSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 15)

    /// The symbology for the example polygon area.
    static let polygonOutlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .green, width: 2)
    static let polygonFillSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .green, outline: polygonOutlineSymbol)
    
    /// Create the point collection that defines the polygon with a computed variable.
    static var createdPolygon: AGSPolygon {
        let polygonBuilder = AGSPolygonBuilder(spatialReference: .webMercator())
        polygonBuilder.addPointWith(x: -5991501.677830, y: 5599295.131468)
        polygonBuilder.addPointWith(x: -6928550.398185, y: 2087936.739807)
        polygonBuilder.addPointWith(x: -3149463.800709, y: 1840803.011362)
        polygonBuilder.addPointWith(x: -1563689.043184, y: 3714900.452072)
        polygonBuilder.addPointWith(x: -3180355.516764, y: 5619889.608838)
        return polygonBuilder.toGeometry()
    }
    
    /// The graphics overlay for the polygon and points..
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// The graphic for the convex hull - comprised of either a point, a polyline or a polygon shape.
    let polygonGraphic = AGSGraphic(geometry: createdPolygon, symbol: polygonFillSymbol)
    let tappedLocationGraphic = AGSGraphic(geometry: nil, symbol: tappedLocationSymbol)
    let nearestCoordinateGraphic = AGSGraphic(geometry: nil, symbol: nearestCoordinateSymbol)
    let nearestVertexGraphic = AGSGraphic(geometry: nil, symbol: nearestVertexSymbol)
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(graphicsOverlay)
            mapView.setViewpointCenter(AGSPoint(x: -4487263.495911, y: 3699176.480377, spatialReference: .webMercator()), scale: 2e8)
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
    
    /// Add the graphics to the graphics overlay.
    func addGraphicsToMap() {
        graphicsOverlay.graphics.add(polygonGraphic)
        graphicsOverlay.graphics.add(nearestCoordinateGraphic)
        graphicsOverlay.graphics.add(tappedLocationGraphic)
        graphicsOverlay.graphics.add(nearestVertexGraphic)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGraphicsToMap()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ConvexHullViewController"]
    }
}

extension NearestVertexViewController: AGSGeoViewTouchDelegate {
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //if the callout is not shown, show the callout with the coordinates of the tapped location
        if self.mapView.callout.isHidden {
            guard
                let nearestVertexResult = AGSGeometryEngine.nearestVertex(in: polygonGraphic.geometry!, to: mapPoint),
                let nearestCoordinateResult = AGSGeometryEngine.nearestCoordinate(in: polygonGraphic.geometry!, to: mapPoint)
            else {
                // Display the error as an alert if there is a problem with AGSGeometryEngine.nearestVertex operation.
                let alertController = UIAlertController(title: nil, message: "Geometry Engine Failed!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                present(alertController, animated: true)
                return
            }
            // Get the distance to the nearest vertex in the polygon
            let distanceVertex = nearestVertexResult.distance / 1000
            // Get the distance to the nearest coordinate in the polygon
            let distanceCoordinate = nearestCoordinateResult.distance / 1000
            
            tappedLocationGraphic.geometry = mapPoint
            nearestVertexGraphic.geometry = nearestVertexResult.point
            nearestCoordinateGraphic.geometry = nearestCoordinateResult.point
            
            self.mapView.callout.title = "Proximity result"
            self.mapView.callout.detail = String(format: "Vertex dist: %.2f km, Point dist: %.2f km", distanceVertex, distanceCoordinate)
            self.mapView.callout.isAccessoryButtonHidden = true
            self.mapView.callout.show(at: mapPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
        } else {
            self.mapView.callout.dismiss()
            tappedLocationGraphic.geometry = nil
            nearestVertexGraphic.geometry = nil
            nearestCoordinateGraphic.geometry = nil
        }
    }
}
