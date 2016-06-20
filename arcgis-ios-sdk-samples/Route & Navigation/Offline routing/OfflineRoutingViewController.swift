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

class OfflineRoutingViewController: UIViewController, AGSMapViewTouchDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var segmentedControl:UISegmentedControl!
    
    var map:AGSMap!
    var routeTask:AGSRouteTask!
    var params:AGSRouteParameters!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var longPressedGraphic:AGSGraphic!
    private var longPressedRouteGraphic:AGSGraphic!
    private var routeTaskOperation:AGSCancellable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineRoutingViewController"]
        
        //using a tpk to create a local tiled layer
        //which will be visible in case of no network connection
        let path = NSBundle.mainBundle().pathForResource("streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(path: path))
        
        //initialize the map using the local tiled layer as baselayer
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //register self as the touch delegate for the map view
        //will be using the touch gestures to add the stops
        self.mapView.touchDelegate = self
        
        //add graphics overlay, one for the stop graphics
        //and other for the route graphics
        self.mapView.graphicsOverlays.addObjectsFromArray([self.routeGraphicsOverlay, self.stopGraphicsOverlay])
        
        //setup route task
        self.setupRouteTask()
        
        //zoom to San Diego
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 2e4, completion: nil)
        
        //enable magnifier for better experience while using tap n hold to add a stop
        self.mapView.magnifierEnabled = true
    }
    
    //method returns a graphic for the specified location
    //also assigns the stop number
    private func graphicForLocation(point:AGSPoint) -> AGSGraphic {
        let symbol = AGSTextSymbol(text: "\(self.stopGraphicsOverlay.graphics.count)", color: UIColor.redColor(), size: 20, horizontalAlignment: AGSHorizontalAlignment.Center, verticalAlignment: AGSVerticalAlignment.Middle)
        let graphic = AGSGraphic(geometry: point, symbol: symbol)
        return graphic
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //on single tap, add stop graphic at the tapped location
        //and route
        let graphic = self.graphicForLocation(mappoint)
        self.stopGraphicsOverlay.graphics.addObject(graphic)
        
        //clear the route graphic
        self.longPressedRouteGraphic = nil
        
        self.route(false)
    }
    
    func mapView(mapView: AGSMapView, didLongPressAtScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //add the graphic at that point
        //keep a reference to that graphic to update the geometry if moved
        self.longPressedGraphic = self.graphicForLocation(mappoint)
        self.stopGraphicsOverlay.graphics.addObject(self.longPressedGraphic)
        //clear the route graphic
        self.longPressedRouteGraphic = nil
        //route
        self.route(true)
    }
    
    func mapView(mapView: AGSMapView, didMoveLongPressToScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //update the graphic
        //route
        self.longPressedGraphic.geometry = mappoint
        self.route(true)
    }
    
    //MARK: - Route logic
    
    private func setupRouteTask() {
        //get the path for the geodatabase in the bundle
        let path = NSBundle.mainBundle().pathForResource("sandiego", ofType: "geodatabase", inDirectory: "san-diego")!
        //initialize the route task using the path and the network name
        self.routeTask = AGSRouteTask(pathToDatabase: path, networkName: "Streets_ND")
        //load the task and get the default parameters
        self.routeTask.loadWithCompletion { [weak self] (error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.getDefaultParameters()
            }
        }
    }
    
    private func getDefaultParameters() {
        //get the default parameters
        self.routeTask.defaultRouteParametersWithCompletion({ [weak self] (params: AGSRouteParameters?, error: NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.params = params
            }
        })
    }
    
    func route(isLongPressed:Bool) {
        //if either default parameters failed to generate or
        //the number of stops is less than two, return
        if self.params == nil {
            print("Failed to generate default parameters")
            return
        }
        if self.stopGraphicsOverlay.graphics.count < 2 {
            print("The stop count is less than 2")
            return
        }
        
        //cancel previous requests
        self.routeTaskOperation?.cancel()
        self.routeTaskOperation = nil
        
        //create stops using the last two graphics in the overlay
        let count = self.stopGraphicsOverlay.graphics.count
        let geometry1 = (self.stopGraphicsOverlay.graphics[count-2] as! AGSGraphic).geometry as! AGSPoint
        let geometry2 = (self.stopGraphicsOverlay.graphics[count-1] as! AGSGraphic).geometry as! AGSPoint
        let stop1 = AGSStop(point: (geometry1))
        let stop2 = AGSStop(point: (geometry2))
        let stops = [stop1, stop2]
        
        //clear the previous stops
        self.params.clearStops()
        //add the new stops
        self.params.setStops(stops)
        
        //set the new travel mode
        self.params.travelMode = self.routeTask.routeTaskInfo().travelModes[self.segmentedControl.selectedSegmentIndex]
        
        self.route(self.params, isLongPressed: isLongPressed)
    }
    
    func route(params:AGSRouteParameters, isLongPressed:Bool) {
        
        //solve for route
        self.routeTaskOperation = self.routeTask.solveRouteWithParameters(params) { [weak self] (routeResult:AGSRouteResult?, error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                //handle the route result
                self?.displayRoutesOnMap(routeResult?.routes, isLongPressedResult: isLongPressed)
            }
        }
    }
    
    func displayRoutesOnMap(routes:[AGSRoute]?, isLongPressedResult:Bool) {
        //if a route graphic for previous request (in case of long press)
        //exists then remove it
        if self.longPressedRouteGraphic != nil {
            self.routeGraphicsOverlay.graphics.removeObject(self.longPressedRouteGraphic)
            self.longPressedRouteGraphic = nil
        }
        
        //if a route is returned, create a graphic for it
        //and add to the route graphics overlay
        if let route = routes?[0] {
            let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self.routeSymbol())
            //keep reference to the graphic in case of long press
            //to remove in case of cancel or move
            if isLongPressedResult {
                self.longPressedRouteGraphic = routeGraphic
            }
            self.routeGraphicsOverlay.graphics.addObject(routeGraphic)
        }
    }
    
    //method returns the symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .Solid, color: UIColor.yellowColor(), width: 5)
        return symbol
    }
    
    //MARK: - Actions
    
    @IBAction func trashAction() {
        //empty both graphic overlays
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.stopGraphicsOverlay.graphics.removeAllObjects()
    }
    
    @IBAction func modeChanged(segmentedControl:UISegmentedControl) {
        //re route for already added stops
        if self.stopGraphicsOverlay.graphics.count > 1 {
            var stops = [AGSStop]()
            for graphic in self.stopGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
                let stop = AGSStop(point: graphic.geometry! as! AGSPoint)
                stops.append(stop)
            }
            
            self.params.clearStops()
            self.params.setStops(stops)
            
            //set the new travel mode
            self.params.travelMode = self.routeTask.routeTaskInfo().travelModes[self.segmentedControl.selectedSegmentIndex]
            
            //clear all previous routes
            self.routeGraphicsOverlay.graphics.removeAllObjects()
            //route
            self.route(self.params, isLongPressed: false)
        }
    }
}
