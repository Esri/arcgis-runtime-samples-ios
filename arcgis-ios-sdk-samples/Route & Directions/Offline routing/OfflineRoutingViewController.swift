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

class OfflineRoutingViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var segmentedControl:UISegmentedControl!
    @IBOutlet var distanceLabel:UILabel!
    @IBOutlet var timeLabel:UILabel!
    @IBOutlet var detailsViewBottomContraint:NSLayoutConstraint!
    
    var map:AGSMap!
    var routeTask:AGSRouteTask!
    var params:AGSRouteParameters!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var longPressedGraphic:AGSGraphic!
    private var longPressedRouteGraphic:AGSGraphic!
    private var routeTaskOperation:AGSCancelable!
    
    private var totalDistance:Double = 0 {
        didSet {
            let miles = String(format: "%.2f", totalDistance * 0.000621371)
            self.distanceLabel?.text = "(\(miles) mi)"
        }
    }
    private var totalTime:Double = 0 {
        didSet {
            var minutes = Int(totalTime)
            let hours = minutes / 60
            minutes = minutes % 60
            let hoursString = hours == 0 ? "" : "\(hours) hr "
            let minutesString = minutes == 0 ? "0 min" : "\(minutes) min"
            self.timeLabel?.text = "\(hoursString)\(minutesString)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineRoutingViewController"]
        
        //using a tpk to create a local tiled layer
        //which will be visible in case of no network connection
        let path = Bundle.main.path(forResource: "streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: URL(fileURLWithPath: path)))
        
        //initialize the map using the local tiled layer as baselayer
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //register self as the touch delegate for the map view
        //will be using the touch gestures to add the stops
        self.mapView.touchDelegate = self
        
        //add graphics overlay, one for the stop graphics
        //and other for the route graphics
        self.mapView.graphicsOverlays.addObjects(from: [self.routeGraphicsOverlay, self.stopGraphicsOverlay])
        
        //get the path for the geodatabase in the bundle
        let dbPath = Bundle.main.path(forResource: "sandiego", ofType: "geodatabase", inDirectory: "san-diego")!
        
        //initialize the route task using the path and the network name
        self.routeTask = AGSRouteTask(fileURLToDatabase: URL(fileURLWithPath: dbPath), networkName: "Streets_ND")
        
        //get default route parameters
        self.getDefaultParameters()
        
        //zoom to San Diego
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 2e4, completion: nil)
        
        //enable magnifier for better experience while using tap n hold to add a stop
        self.mapView.interactionOptions.isMagnifierEnabled = true
    }
    
    //method returns a graphic for the specified location
    //also assigns the stop number
    private func graphicForLocation(_ point:AGSPoint) -> AGSGraphic {
        let symbol = self.symbolForStopGraphic(withIndex: self.stopGraphicsOverlay.graphics.count + 1)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        return graphic
    }
    
    private func symbolForStopGraphic(withIndex index: Int) -> AGSSymbol {
        let markerImage = UIImage(named: "BlueMarker")!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        
        let textSymbol = AGSTextSymbol(text: "\(index)", color: .white, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
        textSymbol.offsetY = markerSymbol.offsetY
        
        let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
        
        return compositeSymbol
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //on single tap, add stop graphic at the tapped location
        //and route
        let graphic = self.graphicForLocation(mapPoint)
        self.stopGraphicsOverlay.graphics.add(graphic)
        
        //clear the route graphic
        self.longPressedRouteGraphic = nil
        
        self.route(isLongPressed: false)
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //add the graphic at that point
        //keep a reference to that graphic to update the geometry if moved
        self.longPressedGraphic = self.graphicForLocation(mapPoint)
        self.stopGraphicsOverlay.graphics.add(self.longPressedGraphic)
        //clear the route graphic
        self.longPressedRouteGraphic = nil
        //route
        self.route(isLongPressed: true)
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //update the graphic
        //route
        self.longPressedGraphic.geometry = mapPoint
        self.route(isLongPressed: true)
    }
    
    //MARK: - Route logic
    
    private func getDefaultParameters() {
        //get the default parameters
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.params = params
            }
        }
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
        
        //get the geometries for the last two graphics in the overlay
        let count = self.stopGraphicsOverlay.graphics.count
        
        guard let geometry1 = (self.stopGraphicsOverlay.graphics[count-2] as? AGSGraphic)?.geometry as? AGSPoint else {
            print("Graphic's geometry is invalid")
            return
        }
        
        guard let geometry2 = (self.stopGraphicsOverlay.graphics[count-1] as? AGSGraphic)?.geometry as? AGSPoint else {
            print("Graphic's geometry is invalid")
            return
        }
        
        //create stops using the last two graphics in the overlay
        let stop1 = AGSStop(point: (geometry1))
        let stop2 = AGSStop(point: (geometry2))
        let stops = [stop1, stop2]
        
        //clear the previous stops
        self.params.clearStops()
        //add the new stops
        self.params.setStops(stops)
        
        //set the new travel mode
        self.params.travelMode = self.routeTask.routeTaskInfo().travelModes[self.segmentedControl.selectedSegmentIndex]
        
        self.route(with: self.params, isLongPressed: isLongPressed)
    }
    
    func route(with params:AGSRouteParameters, isLongPressed:Bool) {
        
        //solve for route
        self.routeTaskOperation = self.routeTask.solveRoute(with: params) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            
            if let error = error as NSError?, error.code != NSUserCancelledError {
                print(error)
            }
            else {
                //handle the route result
                self?.displayRoutesOnMap(routeResult?.routes, isLongPressedResult: isLongPressed)
            }
        }
    }
    
    func displayRoutesOnMap(_ routes:[AGSRoute]?, isLongPressedResult:Bool) {
        //if a route graphic for previous request (in case of long press)
        //exists then remove it
        if self.longPressedRouteGraphic != nil {
            //update distance and time
            self.totalTime = self.totalTime - Double(truncating: self.longPressedGraphic.attributes["routeTime"] as! NSNumber)
            self.totalDistance = self.totalDistance - Double(truncating: self.longPressedGraphic.attributes["routeLength"] as! NSNumber)
            
            self.routeGraphicsOverlay.graphics.remove(self.longPressedRouteGraphic)
            self.longPressedRouteGraphic = nil
            
        }
        
        //if a route is returned, create a graphic for it
        //and add to the route graphics overlay
        if let route = routes?[0] {
            let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self.routeSymbol(), attributes: nil)
            //keep reference to the graphic in case of long press
            //to remove in case of cancel or move
            if isLongPressedResult {
                self.longPressedRouteGraphic = routeGraphic
                
                //set attributes (to subtract in case the route is not used)
                self.longPressedGraphic.attributes["routeTime"] = route.totalTime
                self.longPressedGraphic.attributes["routeLength"] = route.totalLength
            }
            self.routeGraphicsOverlay.graphics.add(routeGraphic)
            
            //update total distance and total time
            self.totalTime = self.totalTime + route.totalTime
            self.totalDistance = self.totalDistance + route.totalLength
            
            self.toggleDetailsView(on: true)
        }
    }
    
    //method returns the symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        return symbol
    }
    
    //MARK: - Actions
    
    @IBAction func trashAction() {
        //empty both graphic overlays
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.stopGraphicsOverlay.graphics.removeAllObjects()
        
        //reset distance and time
        self.totalTime = 0
        self.totalDistance = 0
        
        //hide the details view
        self.toggleDetailsView(on: false)
    }
    
    @IBAction func modeChanged(_ segmentedControl:UISegmentedControl) {
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
            
            //reset distance and time
            self.totalDistance = 0
            self.totalTime = 0
            
            //route
            self.route(with: self.params, isLongPressed: false)
        }
    }
    
    //MARK: toggle details view
    
    private func toggleDetailsView(on: Bool) {
        self.detailsViewBottomContraint.constant = on ? 0 : -36
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
}
