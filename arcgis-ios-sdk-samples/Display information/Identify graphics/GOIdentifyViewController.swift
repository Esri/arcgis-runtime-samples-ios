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

class GOIdentifyViewController: UIViewController, AGSMapViewTouchDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GOIdentifyViewController"]
        
        //initialize the map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addGraphicsOverlay() {
        //polygon graphic
        let polygonGeometry = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygonGeometry.addPointWithX(-20e5, y: 20e5)
        polygonGeometry.addPointWithX(20e5, y: 20e5)
        polygonGeometry.addPointWithX(20e5, y: -20e5)
        polygonGeometry.addPointWithX(-20e5, y: -20e5)
        let polygonSymbol = AGSSimpleFillSymbol(style: AGSSimpleFillSymbolStyle.Solid, color: UIColor.yellowColor(), opacity: 0.7, outline: nil)
        let polygonGraphic = AGSGraphic(geometry: polygonGeometry.toGeometry())
        
        //initialize the graphics overlay
        self.graphicsOverlay = AGSGraphicsOverlay()
        //assign the renderer
        self.graphicsOverlay.renderer = AGSSimpleRenderer(symbol: polygonSymbol)
        //add the polygon graphic
        self.graphicsOverlay.graphics.addObject(polygonGraphic)
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!) {
        //use the following method to identify graphics in a specific graphics overlay
        //otherwise if you need to identify on all the graphics overlay present in the map view
        //use `identifyGraphicsOverlaysAtScreenCoordinate:tolerance:maximumGraphics:completion:` method provided on map view
        let tolerance:Double = 44
        
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenCoordinate: screen, tolerance: tolerance, maximumGraphics: 10) { [weak self] (graphics:[AnyObject]?, error:NSError?) -> Void in
            if let error = error {
                println("error while identifying :: \(error.localizedDescription)")
            }
            else {
                //if a graphics is found then show an alert
                if graphics?.count > 0 {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        UIAlertView(title: "Alert", message: "Tapped on graphic", delegate: nil, cancelButtonTitle: "Ok").show()
                    })
                }
            }
        }
    }
}
