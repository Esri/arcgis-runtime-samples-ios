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

    @IBOutlet private var mapView:AGSMapView!

    private var graphicsOverlay = AGSGraphicsOverlay()
    private var originGraphic: AGSGraphic!
    private var destinationGraphic: AGSGraphic!
    private var pathGraphic: AGSGraphic!
    let JFKAirportLocation = AGSPoint(x: -73.7781, y: 40.6413, spatialReference: AGSSpatialReference.wgs84())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GeodesicOperationsViewController"]
        
        // Initialize map with imagery basemap.
        let map = AGSMap(basemap: AGSBasemap.imagery())
        
        // Assign map to map view.
        mapView.map = map
        
        // Add graphics overlay to the map view.
        mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        // Set map view touch delegate to self.
        mapView.touchDelegate = self
        
        // Add origin graphic, destination graphic, and path graphic.
        addGraphics()
    }
    
    func addGraphics() {
        // Create graphic symbols.
        let locationMarker = AGSSimpleMarkerSymbol(style: .cross, color: .blue, size: 10)
        let pathSymbol = AGSSimpleLineSymbol(style: .dash, color: .blue, width: 5)
        
        // Create origin graphic.
        let originGraphic = AGSGraphic(geometry: JFKAirportLocation, symbol: locationMarker, attributes: nil)
        graphicsOverlay.graphics.add(originGraphic)
        
        // Create destination graphic.
        destinationGraphic = AGSGraphic(geometry: nil, symbol: locationMarker, attributes: nil)
        graphicsOverlay.graphics.add(destinationGraphic)
    
        // Create graphic to represent geodesic path between origin and destination.
        pathGraphic = AGSGraphic(geometry: nil, symbol: pathSymbol, attributes: nil)
        graphicsOverlay.graphics.add(pathGraphic)
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
        
        // Update geometry of destination graphic.
        destinationGraphic.geometry = destinationLocation
        
        // Create a straight line path from origin to destination.
        let path = AGSPolyline(points: [JFKAirportLocation, destinationLocation])
        
        // Densify the polyline to show the geodesic curve.
        guard let geodeticPath = AGSGeometryEngine.geodeticDensifyGeometry(path, maxSegmentLength: 1, lengthUnit: .kilometers(), curveType: .geodesic) else {
            return
        }
        
        // Update geometry of path graphic.
        pathGraphic.geometry = geodeticPath
        
        // Calculate geodetic distance between origin and destination.
        let distance = AGSGeometryEngine.geodeticLength(of: geodeticPath, lengthUnit: .kilometers(), curveType: .geodesic)
        
        // Display the distance in mapview's callout.
        mapView.callout.title = "Distance"
        mapView.callout.detail = String(format: "%.2f km", locale: Locale.current, distance)
        mapView.callout.isAccessoryButtonHidden = true
        mapView.callout.show(at: mapPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
    }

}
