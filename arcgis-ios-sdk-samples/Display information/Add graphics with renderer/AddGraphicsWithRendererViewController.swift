// Copyright 2016 Esri.
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

class AddGraphicsWithRendererViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
        }
    }
    
    // MARK: Methods
    
    /// Add graphics overlays with various renderers.
    func addGraphicsOverlays() {
        // Create a graphics overlay for the points.
        let pointGraphicsOverlay = makePointGraphicsOverlay()
        // Create a point graphic with `AGSPoint` geometry.
        let pointGeometry = AGSPoint(x: 40e5, y: 40e5, spatialReference: .webMercator())
        let pointGraphic = AGSGraphic(geometry: pointGeometry, symbol: nil)
        // Add the graphic to the overlay.
        pointGraphicsOverlay.graphics.add(pointGraphic)
        
        // Create a graphics overlay for the polylines.
        let lineGraphicsOverlay = makeLineGraphicsOverlay()
        // Create a line graphic with `AGSPolyline` geometry.
        let lineBuilder = AGSPolylineBuilder(spatialReference: .webMercator())
        lineBuilder.addPointWith(x: -10e5, y: 40e5)
        lineBuilder.addPointWith(x: 20e5, y: 50e5)
        let lineGraphic = AGSGraphic(geometry: lineBuilder.toGeometry(), symbol: nil)
        // Add the graphic to the overlay.
        lineGraphicsOverlay.graphics.add(lineGraphic)
        
        // Create a graphics overlay for the polygons.
        let polygonGraphicsOverlay = makePolygonGraphicsOverlay()
        // Create a polygon graphic with `AGSPolygon` geometry.
        let polygonBuilder = AGSPolygonBuilder(spatialReference: .webMercator())
        polygonBuilder.addPointWith(x: -20e5, y: 20e5)
        polygonBuilder.addPointWith(x: 20e5, y: 20e5)
        polygonBuilder.addPointWith(x: 20e5, y: -20e5)
        polygonBuilder.addPointWith(x: -20e5, y: -20e5)
        let polygonGraphic = AGSGraphic(geometry: polygonBuilder.toGeometry(), symbol: nil)
        // Add the graphic to the overlay.
        polygonGraphicsOverlay.graphics.add(polygonGraphic)
        
        // Create a graphics overlay for the enclosing shapes with curve segments.
        let curveGraphicsOverlay = makeCurveGraphicsOverlay()
        let origin = AGSPoint(x: 40e5, y: 5e5, spatialReference: .webMercator())
        // Create a heart-shape graphic from `AGSSegment`s.
        let heartGeometry = makeHeartGeometry(center: origin, sideLength: 10e5)
        let heartGraphic = AGSGraphic(geometry: heartGeometry, symbol: nil)
        curveGraphicsOverlay.graphics.add(heartGraphic)
        
        // Add the overlays to the map view.
        mapView.graphicsOverlays.addObjects(from: [pointGraphicsOverlay, lineGraphicsOverlay, polygonGraphicsOverlay, curveGraphicsOverlay])
    }
    
    func makePointGraphicsOverlay() -> AGSGraphicsOverlay {
        // Create a simple marker symbol.
        let pointSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .green, size: 10)
        // Create a graphics overlay for the points.
        let pointGraphicsOverlay = AGSGraphicsOverlay()
        // Create and assign a simple renderer to the graphics overlay.
        pointGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: pointSymbol)
        return pointGraphicsOverlay
    }
    
    func makeLineGraphicsOverlay() -> AGSGraphicsOverlay {
        // Create a simple line symbol.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 5)
        // Create a graphics overlay for the polylines.
        let lineGraphicsOverlay = AGSGraphicsOverlay()
        // Create and assign a simple renderer to the graphics overlay.
        lineGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: lineSymbol)
        return lineGraphicsOverlay
    }
    
    func makePolygonGraphicsOverlay() -> AGSGraphicsOverlay {
        // Create a simple fill symbol.
        let polygonSymbol = AGSSimpleFillSymbol(style: .solid, color: .yellow, outline: nil)
        // Create a graphics overlay for the polygons.
        let polygonGraphicsOverlay = AGSGraphicsOverlay()
        // Create and assign a simple renderer to the graphics overlay.
        polygonGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: polygonSymbol)
        return polygonGraphicsOverlay
    }
    
    func makeCurveGraphicsOverlay() -> AGSGraphicsOverlay {
        // Create a simple fill symbol with outline.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let filledSymbol = AGSSimpleFillSymbol(style: .solid, color: .red, outline: lineSymbol)
        // Create a graphics overlay for the polygons with curve segments.
        let graphicsOverlay = AGSGraphicsOverlay()
        // Create and assign a simple renderer to the graphics overlay.
        graphicsOverlay.renderer = AGSSimpleRenderer(symbol: filledSymbol)
        return graphicsOverlay
    }
    
    /// Create a heart-shape geometry with Bezier and elliptic arc segments.
    ///
    /// - Parameters:
    ///   - center: The center of the square that contains the heart shape.
    ///   - sideLength: The side length of the square.
    /// - Returns: A heart-shape geometry.
    func makeHeartGeometry(center: AGSPoint, sideLength: Double) -> AGSGeometry? {
        guard sideLength > 0 else { return nil }
        let spatialReference = center.spatialReference
        // The x and y coordinates to simplify the calculation.
        let minX = center.x - 0.5 * sideLength
        let minY = center.y - 0.5 * sideLength
        // The radius of the arcs.
        let arcRadius = sideLength * 0.25
        
        // Bottom left curve.
        let leftCurveStart = AGSPoint(x: center.x, y: minY, spatialReference: spatialReference)
        let leftCurveEnd = AGSPoint(x: minX, y: minY + 0.75 * sideLength, spatialReference: spatialReference)
        let leftControlPoint1 = AGSPoint(x: center.x, y: minY + 0.25 * sideLength, spatialReference: spatialReference)
        let leftControlPoint2 = AGSPoint(x: minX, y: center.y, spatialReference: spatialReference)
        let leftCurve = AGSCubicBezierSegment(start: leftCurveStart, controlPoint1: leftControlPoint1, controlPoint2: leftControlPoint2, end: leftCurveEnd, spatialReference: spatialReference)!
        
        // Top left arc.
        let leftArcCenter = AGSPoint(x: minX + 0.25 * sideLength, y: minY + 0.75 * sideLength, spatialReference: spatialReference)
        let leftArc = AGSEllipticArcSegment.createCircularEllipticArc(withCenter: leftArcCenter, radius: arcRadius, startAngle: .pi, centralAngle: -.pi, spatialReference: spatialReference)!
        
        // Top right arc.
        let rightArcCenter = AGSPoint(x: minX + 0.75 * sideLength, y: minY + 0.75 * sideLength, spatialReference: spatialReference)
        let rightArc = AGSEllipticArcSegment.createCircularEllipticArc(withCenter: rightArcCenter, radius: arcRadius, startAngle: .pi, centralAngle: -.pi, spatialReference: spatialReference)!
        
        // Bottom right curve.
        let rightCurveStart = AGSPoint(x: minX + sideLength, y: minY + 0.75 * sideLength, spatialReference: spatialReference)
        let rightCurveEnd = leftCurveStart
        let rightControlPoint1 = AGSPoint(x: minX + sideLength, y: center.y, spatialReference: spatialReference)
        let rightControlPoint2 = leftControlPoint1
        let rightCurve = AGSCubicBezierSegment(start: rightCurveStart, controlPoint1: rightControlPoint1, controlPoint2: rightControlPoint2, end: rightCurveEnd, spatialReference: spatialReference)!
        
        let heart = [leftCurve, leftArc, rightArc, rightCurve].reduce(AGSMutablePart(spatialReference: spatialReference)) { (part: AGSMutablePart, segment: AGSSegment) -> AGSMutablePart in
            part.add(segment)
            return part
        }
        let heartShape = AGSPolygonBuilder(spatialReference: spatialReference)
        heartShape.parts.add(heart)
        return heartShape.toGeometry()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AddGraphicsWithRendererViewController"]
        
        // Add the graphics overlays, with graphics added, to the map view.
        addGraphicsOverlays()
    }
}
