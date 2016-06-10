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

class MobileMapViewController: UIViewController, AGSMapViewTouchDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    var map:AGSMap!
    var locatorTask:AGSLocatorTask?
    
    private var markerGraphicsOverlay = AGSGraphicsOverlay()
    private var labelGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    
    private var locatorTaskCancellable:AGSCancellable!
    private var routeTaskCancellable:AGSCancellable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize reverse geocode params
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
        self.reverseGeocodeParameters.resultAttributeNames.appendContentsOf(["*"])

        //set the map on to the map view
        self.mapView.map = self.map
        
        //touch delegate
        self.mapView.touchDelegate = self
        
        //add graphic overlays
        self.mapView.graphicsOverlays.addObjectsFromArray([self.routeGraphicsOverlay, self.markerGraphicsOverlay, self.labelGraphicsOverlay])
        
        //route task
        self.setupRouteTask()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func symbolForStop() -> AGSPictureMarkerSymbol {
        let markerImage = UIImage(named: "BlueMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        return symbol
    }
    
    private func labelSymbolForStop(text:String) -> AGSTextSymbol {
        let symbol = AGSTextSymbol(text: text, color: UIColor.whiteColor(), size: 15, horizontalAlignment: .Center, verticalAlignment: .Middle)
        symbol.offsetY = 22
        return symbol
    }
    
    private func graphicForPoint(point:AGSPoint) -> AGSGraphic {
        let graphic = AGSGraphic(geometry: point, symbol: self.symbolForStop())
        return graphic
    }
    
    //method returns the symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .Solid, color: UIColor.blueColor(), width: 5)
        return symbol
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool, offset:Bool) {
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        self.mapView.callout.accessoryButtonHidden = true
        
        self.mapView.callout.showCalloutForGraphic(graphic, overlay: self.markerGraphicsOverlay, tapLocation: tapLocation, animated: animated)
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if self.routeTask == nil && self.locatorTask == nil {
            return
        }
        else if routeTask == nil {
            //if routing is not possible, then clear previous graphics
            self.markerGraphicsOverlay.graphics.removeAllObjects()
        }
        
        //identify to check if a graphic is present
        //if yes, then show callout with geocoding
        //else add a graphic and route if more than one graphic
        
        self.mapView.identifyGraphicsOverlay(self.markerGraphicsOverlay, screenPoint: screenPoint, tolerance: 5) { [weak self] (graphics:[AGSGraphic]?, error:NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                if graphics!.count == 0 {
                    //add a graphic
                    let graphic = self!.graphicForPoint(mapPoint)
                    self?.markerGraphicsOverlay.graphics.addObject(graphic)
                    
                    if self?.routeTask != nil {
                        //label graphic until the composite symbol not available
                        let labelGraphic = AGSGraphic(geometry: mapPoint, symbol: self?.labelSymbolForStop("\(self!.labelGraphicsOverlay.graphics.count+1)"))
                        self!.labelGraphicsOverlay.graphics.addObject(labelGraphic)
                    }
                    
                    //reverse geocode
                    self?.reverseGeocode(mapPoint, graphic: graphic)
                    
                    //find route
                    self?.route()
                }
                else {
                    //reverse geocode
                    self?.reverseGeocode(mapPoint, graphic: graphics![0])
                }
            }
        }
    }
    
    //MARK: - Locator
    
    private func reverseGeocode(point:AGSPoint, graphic:AGSGraphic) {
        if self.locatorTask == nil {
            return
        }
        
        //cancel previous request if any
        if self.locatorTaskCancellable != nil {
            self.locatorTaskCancellable.cancel()
        }
        
        self.locatorTaskCancellable = self.locatorTask?.reverseGeocodeWithLocation(point, parameters: self.reverseGeocodeParameters, completion: { (results:[AGSGeocodeResult]?, error:NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                //assign the label property of result as an attributes to the graphic
                //and show the callout
                if let results = results where results.count > 0 {
                    graphic.attributes["Match_addr"] = results.first!.formattedAddressString
                    self.showCalloutForGraphic(graphic, tapLocation: point, animated: false, offset: false)
                    return
                }
                else {
                    //no result was found
                    SVProgressHUD.showErrorWithStatus("No address found", maskType: .Gradient)
                    
                    //dismiss the callout if already visible
                    self.mapView.callout.dismiss()
                }
            }
        })
    }
    
    //MARK: - Route
    
    private func setupRouteTask() {
        //if map contains network data
        if self.map.transportationNetworks.count > 0 {

            self.routeTask = AGSRouteTask(dataset: self.map.transportationNetworks[0])
            
            //load the task and get the default parameters
            self.routeTask.loadWithCompletion { [weak self] (error:NSError?) -> Void in
                if let error = error {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
                }
                else {
                    self?.getDefaultParameters()
                }
            }
        }
    }
    
    private func getDefaultParameters() {
        //get the default parameters
        self.routeTask.defaultRouteParametersWithCompletion { [weak self] (params: AGSRouteParameters?, error: NSError?) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                self?.routeParameters = params
            }
        }
    }
    
    private func route() {
        if self.markerGraphicsOverlay.graphics.count <= 1 || self.routeParameters == nil {
            return
        }
        
        //cancel previous request if any
        if self.routeTaskCancellable != nil {
            self.routeTaskCancellable.cancel()
        }
        
        //create stops for last and second last graphic
        let count = self.markerGraphicsOverlay.graphics.count
        let lastGraphic = self.markerGraphicsOverlay.graphics[count-1] as! AGSGraphic
        let secondLastGraphic = self.markerGraphicsOverlay.graphics[count-2] as! AGSGraphic
        let stops = self.stopsForGraphics([secondLastGraphic, lastGraphic])
        
        //add stops to the parameters
        self.routeParameters.clearStops()
        self.routeParameters.setStops(stops)
        
        //route
        self.routeTaskCancellable = self.routeTask.solveRouteWithParameters(self.routeParameters) { (routeResult:AGSRouteResult?, error:NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
                //remove the last marker
                self.markerGraphicsOverlay.graphics.removeLastObject()
                self.labelGraphicsOverlay.graphics.removeLastObject()
            }
            else {
                if let route = routeResult?.routes[0] {
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self.routeSymbol())
                    self.routeGraphicsOverlay.graphics.addObject(routeGraphic)
                }
            }
        }
    }
    
    private func stopsForGraphics(graphics:[AGSGraphic]) -> [AGSStop] {
        var stops = [AGSStop]()
        for graphic in graphics {
            let stop = AGSStop(point: graphic.geometry as! AGSPoint)
            stops.append(stop)
        }
        return stops
    }
    
    //MARK: - actions
    
    @IBAction private func trashAction() {
        //remove all markers
        self.markerGraphicsOverlay.graphics.removeAllObjects()
        //remove route graphics
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        //remove label graphics
        self.labelGraphicsOverlay.graphics.removeAllObjects()
        //dismiss callout
        self.mapView.callout.dismiss()
    }
}


//extension for extracting the right attributes if available
extension AGSGeocodeResult {
    
    public var formattedAddressString : String? {
        
        if !label.isEmpty {
            return label
        }
        
        let addr = attributes?["Address"] as? String
        let street = attributes?["Street"] as? String
        let city = attributes?["City"] as? String
        let region = attributes?["Region"] as? String
        let neighborhood = attributes?["Neighborhood"] as? String
        
        
        if addr != nil && city != nil && region != nil {
            return "\(addr!), \(city!), \(region!)"
        }
        if addr != nil && neighborhood != nil {
            return "\(addr!), \(neighborhood!)"
        }
        if street != nil && city != nil {
            return "\(street!), \(city!)"
        }
        
        return addr
    }
    
    public func attributeValueAs<T>(key: String) -> T? {
        return attributes![key] as? T
    }
    
    public func attributeAsStringForKey(key: String) -> String? {
        return attributeValueAs(key)
    }
    
    public func attributeAsNonEmptyStringForKey(key: String) -> String? {
        if let value = attributeAsStringForKey(key) {
            return value.isEmpty ? nil : value
        }
        return nil
    }
    
}
