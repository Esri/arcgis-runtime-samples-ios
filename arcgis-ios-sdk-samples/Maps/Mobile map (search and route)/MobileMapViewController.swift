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

class MobileMapViewController: UIViewController, AGSGeoViewTouchDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    var map:AGSMap!
    var locatorTask:AGSLocatorTask?
    
    private var markerGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    
    private var locatorTaskCancelable:AGSCancelable!
    private var routeTaskCancelable:AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize reverse geocode params
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
        self.reverseGeocodeParameters.resultAttributeNames.append(contentsOf: ["*"])

        //set the map on to the map view
        self.mapView.map = self.map
        
        //touch delegate
        self.mapView.touchDelegate = self
        
        //add graphic overlays
        self.mapView.graphicsOverlays.addObjects(from: [self.routeGraphicsOverlay, self.markerGraphicsOverlay])
        
        //route task
        self.setupRouteTask()
    }
    
    private func symbolForStopGraphic(isIndexRequired: Bool, index: Int?) -> AGSSymbol {
        
        let markerImage = UIImage(named: "BlueMarker")!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        markerSymbol.leaderOffsetY = markerSymbol.offsetY
        
        if isIndexRequired && index != nil {
            let textSymbol = AGSTextSymbol(text: "\(index!)", color: .white, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
            textSymbol.offsetY = markerSymbol.offsetY
            
            let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
            return compositeSymbol
        }
        
        return markerSymbol
    }
    
    private func graphicForPoint(_ point:AGSPoint, isIndexRequired: Bool, index: Int?) -> AGSGraphic {
        let symbol = self.symbolForStopGraphic(isIndexRequired: isIndexRequired, index: index)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        return graphic
    }
    
    //method returns the symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 5)
        return symbol
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCalloutForGraphic(_ graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool, offset:Bool) {
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        self.mapView.callout.isAccessoryButtonHidden = true
        
        self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: animated)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
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
        
        self.mapView.identify(self.markerGraphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result:AGSIdentifyGraphicsOverlayResult) in
            if let error = result.error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                if result.graphics.count == 0 {
                    //add a graphic
                    var graphic: AGSGraphic
                    
                    if self?.routeTask != nil {
                        let index = self!.markerGraphicsOverlay.graphics.count + 1
                        graphic = self!.graphicForPoint(mapPoint, isIndexRequired: true, index: index)
                    }
                    else {
                        graphic = self!.graphicForPoint(mapPoint, isIndexRequired: false, index: nil)
                    }
                    
                    self?.markerGraphicsOverlay.graphics.add(graphic)
                    
                    //reverse geocode
                    self?.reverseGeocode(point: mapPoint, withGraphic: graphic)
                    
                    //find route
                    self?.route()
                }
                else {
                    //reverse geocode
                    self?.reverseGeocode(point: mapPoint, withGraphic: result.graphics[0])
                }
            }
        }
    }
    
    //MARK: - Locator
    
    private func reverseGeocode(point:AGSPoint, withGraphic graphic:AGSGraphic) {
        if self.locatorTask == nil {
            return
        }
        
        //cancel previous request if any
        if self.locatorTaskCancelable != nil {
            self.locatorTaskCancelable.cancel()
        }
        
        self.locatorTaskCancelable = self.locatorTask?.reverseGeocode(withLocation: point, parameters: self.reverseGeocodeParameters, completion: { [weak self](results:[AGSGeocodeResult]?, error:Error?) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                //assign the label property of result as an attributes to the graphic
                //and show the callout
                if let results = results , results.count > 0 {
                    graphic.attributes["Match_addr"] = results.first!.formattedAddressString
                    self?.showCalloutForGraphic(graphic, tapLocation: point, animated: false, offset: false)
                    return
                }
                else {
                    //no result was found
                    SVProgressHUD.showError(withStatus: "No address found")
                    
                    //dismiss the callout if already visible
                    self?.mapView.callout.dismiss()
                }
            }
        })
    }
    
    //MARK: - Route
    
    private func setupRouteTask() {
        //if map contains network data
        if self.map.transportationNetworks.count > 0 {

            self.routeTask = AGSRouteTask(dataset: self.map.transportationNetworks[0])
            
            //get default parameters
            self.getDefaultParameters()
        }
    }
    
    private func getDefaultParameters() {
        //get the default parameters
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
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
        if self.routeTaskCancelable != nil {
            self.routeTaskCancelable.cancel()
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
        self.routeTaskCancelable = self.routeTask.solveRoute(with: self.routeParameters) {[weak self] (routeResult:AGSRouteResult?, error:Error?) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                //remove the last marker
                self?.markerGraphicsOverlay.graphics.removeLastObject()
            }
            else {
                if let route = routeResult?.routes[0] {
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self?.routeSymbol(), attributes: nil)
                    self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                }
            }
        }
    }
    
    private func stopsForGraphics(_ graphics:[AGSGraphic]) -> [AGSStop] {
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
    
    public func attributeValueAs<T>(_ key: String) -> T? {
        return attributes![key] as? T
    }
    
    public func attributeAsStringForKey(_ key: String) -> String? {
        return attributeValueAs(key)
    }
    
    public func attributeAsNonEmptyStringForKey(_ key: String) -> String? {
        if let value = attributeAsStringForKey(key) {
            return value.isEmpty ? nil : value
        }
        return nil
    }
    
}
