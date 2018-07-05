//
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

class SimpleRendererViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SimpleRendererViewController"]
        
        //instantiate map with basemap
        let map = AGSMap(basemap: AGSBasemap.imageryWithLabels())
        
        //assign map to the map view
        self.mapView.map = map
        
        //add graphics
        self.addGraphics()
        
        //create and assign simple renderer
        self.addSimpleRenderer()
    }

    private func addGraphics() {
        
        //Create points to add graphics to the map to allow a renderer to style them
        //These are in WGS84 coordinates (Long, Lat)
        let oldFaithfulPoint = AGSPoint(x: -110.828140, y: 44.460458, spatialReference: AGSSpatialReference.wgs84())
        let cascadeGeyserPoint = AGSPoint(x: -110.829004, y: 44.462438, spatialReference: AGSSpatialReference.wgs84())
        let plumeGeyserPoint = AGSPoint(x: -110.829381, y: 44.462735, spatialReference: AGSSpatialReference.wgs84())
        
        //create graphics
        let oldFaithfulGraphic = AGSGraphic(geometry: oldFaithfulPoint, symbol: nil, attributes: nil)
        let cascadeGeyserGraphic = AGSGraphic(geometry: cascadeGeyserPoint, symbol: nil, attributes: nil)
        let plumeGeyserGraphic = AGSGraphic(geometry: plumeGeyserPoint, symbol: nil, attributes: nil)
        
        //add the graphics to the graphics overlay
        self.graphicsOverlay.graphics.addObjects(from: [oldFaithfulGraphic, cascadeGeyserGraphic, plumeGeyserGraphic])
        
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //create an envelope using the points above to zoom to
        let envelope = AGSEnvelope(min: oldFaithfulPoint, max: plumeGeyserPoint)
        
        //set viewpoint on the map view
        self.mapView.setViewpointGeometry(envelope, padding: 100, completion: nil)
    }
    
    private func addSimpleRenderer() {
        //create a simple renderer with red cross symbol
        let simpleRenderer = AGSSimpleRenderer(symbol: AGSSimpleMarkerSymbol(style: .cross, color: .red, size: 12))
        
        //assign the renderer to the graphics overlay
        self.graphicsOverlay.renderer = simpleRenderer
    }

}
