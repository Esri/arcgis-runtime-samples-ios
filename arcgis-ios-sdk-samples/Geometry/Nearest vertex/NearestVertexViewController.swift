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
    /// The graphics and symbology for the tapped point, the nearest vertex and the nearest coordinate.
    let tappedLocationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .orange, size: 15)
    let nearestCoordinateSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .red, size: 10)
    let nearestVertexSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 15)
    
    /// The symbology for the example polygon area.
    let polygonFillSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .green, outline: AGSSimpleLineSymbol(style: .solid, color: .green, width: 2))
    
    /// The graphics overlay for the polygon and points.
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// A formatter to convert units for distance.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        return formatter
    }()
    
    /// The point collection that defines the polygon.
    let createdPolygon: AGSPolygon = {
        let polygonBuilder = AGSPolygonBuilder(spatialReference: .webMercator())
        polygonBuilder.addPointWith(x: -5991501.677830, y: 5599295.131468)
        polygonBuilder.addPointWith(x: -6928550.398185, y: 2087936.739807)
        polygonBuilder.addPointWith(x: -3149463.800709, y: 1840803.011362)
        polygonBuilder.addPointWith(x: -1563689.043184, y: 3714900.452072)
        polygonBuilder.addPointWith(x: -3180355.516764, y: 5619889.608838)
        return polygonBuilder.toGeometry()
    }()
    
    /// The graphic for the polygon, tapped point, nearest coordinate point and nearest vertex point.
    lazy var polygonGraphic = AGSGraphic(geometry: createdPolygon, symbol: polygonFillSymbol)
    lazy var tappedLocationGraphic = AGSGraphic(geometry: nil, symbol: tappedLocationSymbol)
    lazy var nearestCoordinateGraphic = AGSGraphic(geometry: nil, symbol: nearestCoordinateSymbol)
    lazy var nearestVertexGraphic = AGSGraphic(geometry: nil, symbol: nearestVertexSymbol)
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(graphicsOverlay)
            mapView.setViewpointCenter(AGSPoint(x: -4487263.495911, y: 3699176.480377, spatialReference: .webMercator()), scale: 1e8)
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
    
    /// Adds the graphics to the graphics overlay.
    func addGraphicsToOverlay() {
        graphicsOverlay.graphics.addObjects(from: [
            polygonGraphic,
            nearestCoordinateGraphic,
            tappedLocationGraphic,
            nearestVertexGraphic
        ])
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGraphicsToOverlay()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NearestVertexViewController"]
    }
}

extension NearestVertexViewController: AGSGeoViewTouchDelegate {
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if mapView.callout.isHidden {
            // If the callout is not shown, show the callout with the coordinates of the tapped location.
            if let nearestVertexResult = AGSGeometryEngine.nearestVertex(in: polygonGraphic.geometry!, to: mapPoint),
                let nearestCoordinateResult = AGSGeometryEngine.nearestCoordinate(in: polygonGraphic.geometry!, to: mapPoint) {
                // Set the geometry for the tapped point, nearest coordinate point and nearest vertex point.
                tappedLocationGraphic.geometry = mapPoint
                nearestVertexGraphic.geometry = nearestVertexResult.point
                nearestCoordinateGraphic.geometry = nearestCoordinateResult.point
                // Get the distance to the nearest vertex in the polygon.
                let distanceVertex = Measurement(value: nearestVertexResult.distance, unit: UnitLength.meters)
                // Get the distance to the nearest coordinate in the polygon.
                let distanceCoordinate = Measurement(value: nearestCoordinateResult.distance, unit: UnitLength.meters)
                // Display the results on a callout of the tapped point.
                mapView.callout.title = "Proximity result"
                mapView.callout.detail = String(format: "Vertex dist: %@; Point dist: %@", distanceFormatter.string(from: distanceVertex), distanceFormatter.string(from: distanceCoordinate))
                mapView.callout.isAccessoryButtonHidden = true
                mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
            } else {
                // Display the error as an alert if there is a problem with nearestVertex and nearestCoordinate operation.
                let alertController = UIAlertController(title: nil, message: "Geometry Engine Failed!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                present(alertController, animated: true)
            }
        } else {
            // Dismiss the callout and reset geometry for all simple marker graphics.
            mapView.callout.dismiss()
            tappedLocationGraphic.geometry = nil
            nearestVertexGraphic.geometry = nil
            nearestCoordinateGraphic.geometry = nil
        }
    }
}
