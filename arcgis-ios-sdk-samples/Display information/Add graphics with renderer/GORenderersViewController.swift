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

class GORenderersViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GORenderersViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
        //add the graphics overaly, with graphics added, to map view
        self.addGraphicsOverlay()
        
        //assign map to the map view's map
        self.mapView.map = self.map
    }
    
    func addGraphicsOverlay() {
        //point graphic
        let pointGeometry = AGSPoint(x: 40e5, y: 40e5, spatialReference: AGSSpatialReference.webMercator())
        let pointSymbol = AGSSimpleMarkerSymbol(style: AGSSimpleMarkerSymbolStyle.diamond, color: .red, size: 10)
        let pointGraphic = AGSGraphic(geometry: pointGeometry, symbol: nil, attributes: nil)
        
        //create graphics overlay for point
        let pointGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        pointGraphicOverlay.renderer = AGSSimpleRenderer(symbol: pointSymbol)
        
        //add the graphic to the overlay
        pointGraphicOverlay.graphics.add(pointGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.add(pointGraphicOverlay)
        
        
        //line graphic
        let lineGeometry = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
        lineGeometry.addPointWith(x: -10e5, y: 40e5)
        lineGeometry.addPointWith(x: 20e5, y: 50e5)
        let lineSymbol = AGSSimpleLineSymbol(style: AGSSimpleLineSymbolStyle.solid, color: .blue, width: 5)
        let lineGraphic = AGSGraphic(geometry: lineGeometry.toGeometry(), symbol: nil, attributes: nil)
        
        // create graphics overlay for polyline
        let lineGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        lineGraphicOverlay.renderer = AGSSimpleRenderer(symbol: lineSymbol)
        
        //add the graphic to the overlay
        lineGraphicOverlay.graphics.add(lineGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.add(lineGraphicOverlay)
        
        
        //polygon graphic
        let polygonGeometry = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygonGeometry.addPointWith(x: -20e5, y: 20e5)
        polygonGeometry.addPointWith(x: 20e5, y: 20e5)
        polygonGeometry.addPointWith(x: 20e5, y: -20e5)
        polygonGeometry.addPointWith(x: -20e5, y: -20e5)
        let polygonSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.solid, color: .yellow, outline: nil)
        let polygonGraphic = AGSGraphic(geometry: polygonGeometry.toGeometry(), symbol: nil, attributes: nil)
        
        //create graphics overlay for polygon
        let polygonGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        polygonGraphicOverlay.renderer = AGSSimpleRenderer(symbol: polygonSymbol)
        
        //add the graphic to the overlay
        polygonGraphicOverlay.graphics.add(polygonGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.add(polygonGraphicOverlay)
    }
}
