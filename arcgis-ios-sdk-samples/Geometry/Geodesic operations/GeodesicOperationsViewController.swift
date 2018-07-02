// Copyright 2018 Esri.
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

class GeodesicOperationsViewController: UIViewController, AGSGeoViewTouchDelegate {

    @IBOutlet private var mapView: AGSMapView!
    
    private let destinationGraphic: AGSGraphic
    private let pathGraphic: AGSGraphic
    
    private let graphicsOverlay = AGSGraphicsOverlay()
    private let measurementFormatter = MeasurementFormatter()
    private let JFKAirportLocation = AGSPoint(x: -73.7781, y: 40.6413, spatialReference: AGSSpatialReference.wgs84())
    
    /// Add graphics representing origin, destination, and path to a graphics overlay.
    required init?(coder aDecoder: NSCoder) {
        // Create graphic symbols.
        let locationMarker = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 10)
        locationMarker.outline = AGSSimpleLineSymbol(style: .solid, color: .green, width: 5)
        let pathSymbol = AGSSimpleLineSymbol(style: .dash, color: .blue, width: 5)
        
        // Create an origin graphic.
        let originGraphic = AGSGraphic(geometry: JFKAirportLocation, symbol: locationMarker, attributes: nil)
        
        // Create a destination graphic.
        destinationGraphic = AGSGraphic(geometry: nil, symbol: locationMarker, attributes: nil)
        
        // Create a graphic to represent geodesic path between origin and destination.
        pathGraphic = AGSGraphic(geometry: nil, symbol: pathSymbol, attributes: nil)
        
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: [originGraphic, destinationGraphic, pathGraphic])
        
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GeodesicOperationsViewController"]
        
        // Assign map with imagery basemap to the map view.
        mapView.map = AGSMap(basemap: .imagery())
        
        // Add the graphics overlay to the map view.
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        // Set touch delegate on map view as self.
        mapView.touchDelegate = self
    }
    
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // If callout is open, dismiss it.
        if !mapView.callout.isHidden {
            mapView.callout.dismiss()
        }
        
        // Get the tapped geometry projected to WGS84.
        guard let destinationLocation = AGSGeometryEngine.projectGeometry(mapPoint, to: .wgs84()) as? AGSPoint else {
            return
        }
        
        // Update geometry of the destination graphic.
        destinationGraphic.geometry = destinationLocation
        
        // Create a straight line path from origin to destination.
        let path = AGSPolyline(points: [JFKAirportLocation, destinationLocation])
        
        // Densify the polyline to show the geodesic curve.
        guard let geodeticPath = AGSGeometryEngine.geodeticDensifyGeometry(path, maxSegmentLength: 1, lengthUnit: .kilometers(), curveType: .geodesic) else {
            return
        }
        
        // Update geometry of the path graphic.
        pathGraphic.geometry = geodeticPath
        
        // Calculate geodetic distance between origin and destination.
        let distance = AGSGeometryEngine.geodeticLength(of: geodeticPath, lengthUnit: .kilometers(), curveType: .geodesic)
        
        // Display the distance in mapview's callout.
        mapView.callout.title = "Distance"
        
        let measurement = Measurement<UnitLength>(value: distance, unit: .kilometers)
        mapView.callout.detail = measurementFormatter.string(from: measurement)
        
        mapView.callout.isAccessoryButtonHidden = true
        mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
    }

}
