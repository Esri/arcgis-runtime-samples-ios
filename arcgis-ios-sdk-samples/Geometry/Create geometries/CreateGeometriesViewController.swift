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

class CreateGeometriesViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CreateGeometriesViewController"]
        
        //instantiate map using basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to the map view
        self.mapView.map = map
        
        //add graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //create symbols for drawing graphics
        let markerSymbol = AGSSimpleMarkerSymbol(style: .triangle, color: .blue, size: 14)
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 3)
        let fillSymbol = AGSSimpleFillSymbol(style: .cross, color: .blue, outline: nil)
        
        //add a graphic of point, multipoint, polyline and polygon
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: self.createPoint(), symbol: markerSymbol, attributes: nil))
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: self.createMultipoint(), symbol: markerSymbol, attributes: nil))
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: self.createPolyline(), symbol: lineSymbol, attributes: nil))
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: self.createPolygon(), symbol: fillSymbol, attributes: nil))
        
        //use the envelope to set the viewpoint of the map view
        self.mapView.setViewpointGeometry(self.createEnvelope(), padding: 100, completion: nil)
    }
    
    private func createEnvelope() -> AGSEnvelope {
        //create an envelope using minimum and maximum x,y coordinates and a spatial reference
        let envelope = AGSEnvelope(xMin: -123.0, yMin: 33.5, xMax: -101.0, yMax: 48.0, spatialReference: AGSSpatialReference.wgs84())
        return envelope
    }
    
    private func createPoint() -> AGSPoint {
        // create a point using x,y coordinates and a spatial reference
        let point = AGSPoint(x: 34.056295, y: -117.195800, spatialReference: AGSSpatialReference.wgs84())
        return point
    }
    
    private func createMultipoint() -> AGSMultipoint {
        // create a multi point geometry
        let multipointBuilder = AGSMultipointBuilder(spatialReference: AGSSpatialReference.wgs84())
        multipointBuilder.points.addPointWith(x: -121.491014, y: 38.579065) // Sacramento, CA
        multipointBuilder.points.addPointWith(x: -122.891366, y: 47.039231) // Olympia, WA
        multipointBuilder.points.addPointWith(x: -123.043814, y: 44.93326) // Salem, OR
        multipointBuilder.points.addPointWith(x: -119.766999, y: 39.164885) // Carson City, NV
        
        return multipointBuilder.toGeometry()
    }
    
    private func createPolyline() -> AGSPolyline {
        //create a polyline
        let polylineBuilder = AGSPolylineBuilder(spatialReference: AGSSpatialReference.wgs84())
        polylineBuilder.addPointWith(x: -119.992, y: 41.989)
        polylineBuilder.addPointWith(x: -119.994, y: 38.994)
        polylineBuilder.addPointWith(x: -114.620, y: 35.0)
        
        return polylineBuilder.toGeometry()
    }
    
    private func createPolygon() -> AGSPolygon {
        // create a polygon
        let polygonBuilder = AGSPolygonBuilder(spatialReference: AGSSpatialReference.wgs84())
        polygonBuilder.addPointWith(x: -109.048, y: 40.998)
        polygonBuilder.addPointWith(x: -102.047, y: 40.998)
        polygonBuilder.addPointWith(x: -102.037, y: 36.989)
        polygonBuilder.addPointWith(x: -109.048, y: 36.998)
        
        return polygonBuilder.toGeometry()
    }
}
