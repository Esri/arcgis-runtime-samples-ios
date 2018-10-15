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

class GOIdentifyViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GOIdentifyViewController"]
        
        //initialize the map with topographic basemap
        self.map = AGSMap(basemap: .topographic())
        
        //call the method to add a graphics to the map view
        //will be using this graphic to test identify
        self.addGraphicsOverlay()
        
        //assign the map to the map view's map object
        self.mapView.map = self.map
        
        //add self as the touch delegate of the mapview
        //we will be using a method on the delegate to know 
        //when the user tapped on the map view
        self.mapView.touchDelegate = self
        
    }
    
    func addGraphicsOverlay() {
        //polygon graphic
        let polygonGeometry = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygonGeometry.addPointWith(x: -20e5, y: 20e5)
        polygonGeometry.addPointWith(x: 20e5, y: 20e5)
        polygonGeometry.addPointWith(x: 20e5, y: -20e5)
        polygonGeometry.addPointWith(x: -20e5, y: -20e5)
        let polygonSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.solid, color: .yellow, outline: nil)
        let polygonGraphic = AGSGraphic(geometry: polygonGeometry.toGeometry(), symbol: nil, attributes: nil)
        
        //initialize the graphics overlay
        self.graphicsOverlay = AGSGraphicsOverlay()
        //assign the renderer
        self.graphicsOverlay.renderer = AGSSimpleRenderer(symbol: polygonSymbol)
        //add the polygon graphic
        self.graphicsOverlay.graphics.add(polygonGraphic)
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //use the following method to identify graphics in a specific graphics overlay
        //otherwise if you need to identify on all the graphics overlay present in the map view
        //use `identifyGraphicsOverlaysAtScreenCoordinate:tolerance:maximumGraphics:completion:` method provided on map view
        let tolerance:Double = 12
        
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: tolerance, returnPopupsOnly: false, maximumResults: 10) {[weak self] (result: AGSIdentifyGraphicsOverlayResult) -> Void in
            if let error = result.error {
                print("error while identifying :: \(error.localizedDescription)")
            }
            else {
                //if a graphics is found then show an alert
                if result.graphics.count > 0 {
                    self?.presentAlert(message: "Tapped on graphic")
                }
            }
        }
    }
}
