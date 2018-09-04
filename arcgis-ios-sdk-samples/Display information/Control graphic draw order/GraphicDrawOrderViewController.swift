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

class GraphicDrawOrderViewController: UIViewController {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var buttons:[UIButton]!
    
    var map:AGSMap!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var graphics:[AGSGraphic]!
    
    private var drawIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GraphicDrawOrderViewController"]
        
        //create an instance of a map with ESRI topographic basemap
        self.map = AGSMap(basemap: .streets())
        //assign map to the map view
        self.mapView.map = self.map
        
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //add the graphics to the overlay
        self.addGraphics()
        
        //set map scale
        let mapScale:Double = 53500
        
        //initial viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13148960, y: 4000040, spatialReference: AGSSpatialReference.webMercator()), scale: mapScale, completion: nil)
        
        //restricting map scale to preserve the graphics overlapping
        self.map.minScale = mapScale
        self.map.maxScale = mapScale
    }
    
    private func addGraphics() {
        //starting x and y
        let x:Double = -13149000
        let y:Double = 4e6
        //distance between the graphics
        let delta:Double = 100
        
        //graphics array for reference when a button is tapped
        self.graphics = [AGSGraphic]()
        
        //blue marker
        var geometry = AGSPoint(x: x, y: y, spatialReference: AGSSpatialReference.webMercator())
        var symbol = AGSPictureMarkerSymbol(image: UIImage(named: "BlueMarker")!)
        var graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: nil)
        self.graphics.append(graphic)
        
        //red marker
        geometry = AGSPoint(x: x+delta, y: y, spatialReference: AGSSpatialReference.webMercator())
        symbol = AGSPictureMarkerSymbol(image: UIImage(named: "RedMarker2")!)
        graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: nil)
        self.graphics.append(graphic)
        
        //green marker
        geometry = AGSPoint(x: x, y: y+delta, spatialReference: AGSSpatialReference.webMercator())
        symbol = AGSPictureMarkerSymbol(image: UIImage(named: "GreenMarker")!)
        graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: nil)
        self.graphics.append(graphic)
        
        //Violet marker
        geometry = AGSPoint(x: x+delta, y: y+delta, spatialReference: AGSSpatialReference.webMercator())
        symbol = AGSPictureMarkerSymbol(image: UIImage(named: "VioletMarker")!)
        graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: nil)
        self.graphics.append(graphic)
        
        //add the graphics to the overlay
        self.graphicsOverlay.graphics.addObjects(from: self.graphics)
    }
    
    //MARK: - Actions
    
    @IBAction func buttonAction(_ sender:UIButton) {
        //increment draw index by 1 and assign as the zIndex for the respective graphic
        self.drawIndex += 1
        
        //the button's tag value specifies which graphic to re-index
        //for example, a button tag value of 1 will move self.graphics[1] - the red marker
        self.graphics[sender.tag].zIndex = self.drawIndex
    }
}


