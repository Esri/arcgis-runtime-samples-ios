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
    // MARK: Properties
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.graphicsOverlays.add(graphicsOverlay)
            mapView.setViewpointCenter(polygon.extent.center, scale: 1e8)
            mapView.touchDelegate = self
            mapView.callout.isAccessoryButtonHidden = true
        }
    }
    
    /// The graphics overlay for the polygon and point graphics.
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// The example polygon geometry.
    let polygon: AGSPolygon
    
    /// The graphic for the polygon.
    let polygonGraphic: AGSGraphic
    /// The graphic for the tapped location point.
    let tappedLocationGraphic: AGSGraphic
    /// The graphic for the nearest coordinate point.
    let nearestCoordinateGraphic: AGSGraphic
    /// The graphic for the nearest vertex point.
    let nearestVertexGraphic: AGSGraphic
    
    /// A distance formatter to format distance measurements and units.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        return formatter
    }()
    
    // MARK: Methods
    
    required init?(coder: NSCoder) {
        // Create a point collection that defines the polygon.
        let polygonBuilder = AGSPolygonBuilder(spatialReference: .webMercator())
        polygonBuilder.addPointWith(x: -5991501.677830, y: 5599295.131468)
        polygonBuilder.addPointWith(x: -6928550.398185, y: 2087936.739807)
        polygonBuilder.addPointWith(x: -3149463.800709, y: 1840803.011362)
        polygonBuilder.addPointWith(x: -1563689.043184, y: 3714900.452072)
        polygonBuilder.addPointWith(x: -3180355.516764, y: 5619889.608838)
        
        polygon = polygonBuilder.toGeometry()
        
        // The symbol for the tapped point.
        let tappedLocationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .orange, size: 15)
        // The symbol for the nearest vertex.
        let nearestCoordinateSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .red, size: 10)
        // The symbol for the nearest coordinate.
        let nearestVertexSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 15)
        // The symbol for the example polygon area.
        let polygonFillSymbol = AGSSimpleFillSymbol(
            style: .forwardDiagonal,
            color: .green,
            outline: AGSSimpleLineSymbol(style: .solid, color: .green, width: 2)
        )
        
        polygonGraphic = AGSGraphic(geometry: polygon, symbol: polygonFillSymbol)
        tappedLocationGraphic = AGSGraphic(geometry: nil, symbol: tappedLocationSymbol)
        nearestCoordinateGraphic = AGSGraphic(geometry: nil, symbol: nearestCoordinateSymbol)
        nearestVertexGraphic = AGSGraphic(geometry: nil, symbol: nearestVertexSymbol)
        super.init(coder: coder)
    }
    
    /// Add graphics to the graphics overlay.
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
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NearestVertexViewController"]
        addGraphicsToOverlay()
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension NearestVertexViewController: AGSGeoViewTouchDelegate {
    func showCallout(at mapPoint: AGSPoint) {
        // Get nearest vertex and nearest coordinate results.
        let nearestVertexResult = AGSGeometryEngine.nearestVertex(in: polygon, to: mapPoint)!
        let nearestCoordinateResult = AGSGeometryEngine.nearestCoordinate(in: polygon, to: mapPoint)!
        
        // Set the geometries for the tapped, nearest coordinate and
        // nearest vertex point graphics.
        nearestVertexGraphic.geometry = nearestVertexResult.point
        nearestCoordinateGraphic.geometry = nearestCoordinateResult.point
        
        // Get geodetic distances between tapped and resulting points.
        let nearestVertexGeodeticDistanceResult = AGSGeometryEngine.geodeticDistanceBetweenPoint1(
            mapPoint,
            point2: nearestVertexResult.point,
            distanceUnit: .meters(),
            azimuthUnit: .degrees(),
            curveType: .geodesic
        )!
        let nearestCoordinateGeodeticDistanceResult = AGSGeometryEngine.geodeticDistanceBetweenPoint1(
            mapPoint,
            point2: nearestCoordinateResult.point,
            distanceUnit: .meters(),
            azimuthUnit: .degrees(),
            curveType: .geodesic
        )!
        
        // Get the distance to the nearest vertex in the polygon.
        // Note: use geodetic instead of planar distance
        // (nearestVertexResult.distance) here. See discussion in README.
        let distanceOfVertex = Measurement(
            value: nearestVertexGeodeticDistanceResult.distance,
            unit: UnitLength.meters
        )
        // Get the distance to the nearest coordinate in the polygon.
        // Note: use geodetic instead of planar distance
        // (nearestCoordinateResult.distance) here. See discussion in README.
        let distanceOfCoordinate = Measurement(
            value: nearestCoordinateGeodeticDistanceResult.distance,
            unit: UnitLength.meters
        )
        
        // Display the results in a callout at tapped location.
        mapView.callout.title = "Proximity result"
        mapView.callout.detail = String(
            format: "Vertex dist: %@; Point dist: %@",
            distanceFormatter.string(from: distanceOfVertex),
            distanceFormatter.string(from: distanceOfCoordinate)
        )
        mapView.callout.show(for: tappedLocationGraphic, tapLocation: mapPoint, animated: true)
    }
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if mapView.callout.isHidden {
            // If the callout is hidden, show it at the normalized map point.
            guard let normalizedMapPoint = AGSGeometryEngine.normalizeCentralMeridian(of: mapPoint) as? AGSPoint else { return }
            tappedLocationGraphic.geometry = normalizedMapPoint
            showCallout(at: normalizedMapPoint)
        } else {
            // Dismiss the callout and reset geometries.
            mapView.callout.dismiss()
            tappedLocationGraphic.geometry = nil
            nearestVertexGraphic.geometry = nil
            nearestCoordinateGraphic.geometry = nil
        }
    }
}
