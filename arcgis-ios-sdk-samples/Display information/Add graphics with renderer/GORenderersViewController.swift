// Copyright 2015 Esri.
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
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        //add the graphics overaly, with graphics added, to map view
        self.addGraphicsOverlay()
        
        //assign map to the map view's map
        self.mapView.map = self.map
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addGraphicsOverlay() {
        //point graphic
        let pointGeometry = AGSPoint(x: 40e5, y: 40e5, spatialReference: AGSSpatialReference.webMercator())
        let pointSymbol = AGSSimpleMarkerSymbol(color: UIColor.redColor(), size: 10, style: AGSSimpleMarkerSymbolStyle.Diamond)
        let pointGraphic = AGSGraphic(geometry: pointGeometry)
        
        //create graphics overlay for point
        let pointGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        pointGraphicOverlay.renderer = AGSSimpleRenderer(symbol: pointSymbol)
        
        //add the graphic to the overlay
        pointGraphicOverlay.graphics.addObject(pointGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.addObject(pointGraphicOverlay)
        
        
        //line graphic
        let lineGeometry = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
        lineGeometry.addPointWithX(-10e5, y: 40e5)
        lineGeometry.addPointWithX(20e5, y: 50e5)
        let lineSymbol = AGSSimpleLineSymbol(style: AGSSimpleLineSymbolStyle.Solid, color: UIColor.blueColor(), width: 5)
        let lineGraphic = AGSGraphic(geometry: lineGeometry.toGeometry())
        
        // create graphics overlay for polyline
        let lineGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        lineGraphicOverlay.renderer = AGSSimpleRenderer(symbol: lineSymbol)
        
        //add the graphic to the overlay
        lineGraphicOverlay.graphics.addObject(lineGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.addObject(lineGraphicOverlay)
        
        
        //polygon graphic
        let polygonGeometry = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygonGeometry.addPointWithX(-20e5, y: 20e5)
        polygonGeometry.addPointWithX(20e5, y: 20e5)
        polygonGeometry.addPointWithX(20e5, y: -20e5)
        polygonGeometry.addPointWithX(-20e5, y: -20e5)
        let polygonSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.Solid, color: UIColor.yellowColor(), outline: nil)
        let polygonGraphic = AGSGraphic(geometry: polygonGeometry.toGeometry())
        
        //create graphics overlay for polygon
        let polygonGraphicOverlay = AGSGraphicsOverlay()
        
        //renderer
        polygonGraphicOverlay.renderer = AGSSimpleRenderer(symbol: polygonSymbol)
        
        //add the graphic to the overlay
        polygonGraphicOverlay.graphics.addObject(polygonGraphic)
        
        //add the overlay to the map view
        self.mapView.graphicsOverlays.addObject(polygonGraphicOverlay)
    }
}
