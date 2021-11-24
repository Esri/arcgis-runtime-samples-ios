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
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(makeGraphicsOverlay())
            mapView.setViewpointCenter(polygon.extent.center, scale: 8e6)
            mapView.touchDelegate = self
            mapView.callout.isAccessoryButtonHidden = true
        }
    }
    
    /// The example polygon geometry near San Bernardino County, California.
    let polygon: AGSPolygon = {
        let polygonBuilder = AGSPolygonBuilder(spatialReference: .statePlaneCaliforniaZone5)
        polygonBuilder.addPointWith(x: 6627416.41469281, y: 1804532.53233782)
        polygonBuilder.addPointWith(x: 6669147.89779046, y: 2479145.16609522)
        polygonBuilder.addPointWith(x: 7265673.02678292, y: 2484254.50442408)
        polygonBuilder.addPointWith(x: 7676192.55880379, y: 2001458.66365744)
        polygonBuilder.addPointWith(x: 7175695.94143837, y: 1840722.34474458)
        return polygonBuilder.toGeometry()
    }()
    
    /// The graphic for the tapped location point.
    let tappedLocationGraphic: AGSGraphic = {
        let symbol = AGSSimpleMarkerSymbol(style: .X, color: .orange, size: 15)
        return AGSGraphic(geometry: nil, symbol: symbol)
    }()
    /// The graphic for the nearest coordinate point.
    let nearestCoordinateGraphic: AGSGraphic = {
        let symbol = AGSSimpleMarkerSymbol(style: .diamond, color: .red, size: 10)
        return AGSGraphic(geometry: nil, symbol: symbol)
    }()
    /// The graphic for the nearest vertex point.
    let nearestVertexGraphic: AGSGraphic = {
        let symbol = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 15)
        return AGSGraphic(geometry: nil, symbol: symbol)
    }()
    
    /// A distance formatter to format distance measurements and units.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        return formatter
    }()
    
    // MARK: Methods
    
    /// Create a map.
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(spatialReference: .statePlaneCaliforniaZone5)
        let usStatesGeneralizedLayer = AGSFeatureLayer(
            item: AGSPortalItem(
                portal: .arcGISOnline(withLoginRequired: false),
                itemID: "99fd67933e754a1181cc755146be21ca"),
            layerID: 0
        )
        map.basemap.baseLayers.add(usStatesGeneralizedLayer)
        return map
    }
    
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        let polygonFillSymbol = AGSSimpleFillSymbol(
            style: .forwardDiagonal,
            color: .green,
            outline: AGSSimpleLineSymbol(style: .solid, color: .green, width: 2)
        )
        // The graphic for the polygon.
        let polygonGraphic = AGSGraphic(geometry: polygon, symbol: polygonFillSymbol)
        
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.graphics.addObjects(from: [
            polygonGraphic,
            nearestCoordinateGraphic,
            tappedLocationGraphic,
            nearestVertexGraphic
        ])
        return graphicsOverlay
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NearestVertexViewController"]
    }
}

private extension AGSSpatialReference {
    /// California zone 5 (ftUS) state plane coordinate system.
    static let statePlaneCaliforniaZone5 = AGSSpatialReference(wkid: 2229)!
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
        
        // Get the distance to the nearest vertex in the polygon.
        let distanceVertex = Measurement(
            value: nearestVertexResult.distance,
            unit: UnitLength.feet
        )
        // Get the distance to the nearest coordinate in the polygon.
        let distanceCoordinate = Measurement(
            value: nearestCoordinateResult.distance,
            unit: UnitLength.feet
        )
        
        // Display the results in a callout at tapped location.
        mapView.callout.title = "Proximity result"
        mapView.callout.detail = String(
            format: "Vertex dist: %@; Point dist: %@",
            distanceFormatter.string(from: distanceVertex),
            distanceFormatter.string(from: distanceCoordinate)
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
