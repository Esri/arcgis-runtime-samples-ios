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

class ReverseGeocodeViewController: UIViewController, AGSMapViewTouchDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    private var map:AGSMap!
    
    private var locatorTask:AGSLocatorTask!
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    private let locatorURL = "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ReverseGeocodeViewController"]
        
        //create an instance of a map with ESRI topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //add the graphics overlay
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //zoom to a specific extent
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -117.195, y: 34.058, spatialReference: AGSSpatialReference.WGS84()), scale: 5e4))
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(URL: NSURL(string: self.locatorURL)!)
        
        //initialize parameters
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
    }
    
    private func reverseGeocode(point:AGSPoint) {
        //hide the callout
        self.mapView.callout.dismiss()
        
        //remove already existing graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //normalize point
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(point) as! AGSPoint
        
        let graphic = self.graphicForPoint(normalizedPoint)
        self.graphicsOverlay.graphics.addObject(graphic)
            
        //reverse geocode
        self.locatorTask.reverseGeocodeWithLocation(normalizedPoint, parameters: self.reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: NSError?) -> Void in
            if let error = error {
                self?.showAlert(error.localizedDescription)
            }
            else {
                if let results = results where results.count > 0 {
                    graphic.attributes.addEntriesFromDictionary(results.first!.attributes!)
                    self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint)
                    return
                }
                else {
                    self?.showAlert("No address found")
                }
            }
            self?.graphicsOverlay.graphics.removeObject(graphic)
        }
    }
    
    //method returns a graphic object for the specified point and attributes
    private func graphicForPoint(point: AGSPoint) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, attributes: [String:AnyObject](), symbol: symbol)
        return graphic
    }
    
    //method to show callout for the graphic
    //it gets the attributes from the graphic and populates the title
    //and detail for the callout
    private func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint) {
        let cityString = graphic.attributes["City"] as? String ?? ""
        let addressString = graphic.attributes["Address"] as? String ?? ""
        let stateString = graphic.attributes["State"] as? String ?? ""
        self.mapView.callout.title = addressString
        self.mapView.callout.detail = "\(cityString) \(stateString)"
        self.mapView.callout.accessoryButtonHidden = true
        self.mapView.callout.showCalloutForGraphic(graphic, overlay: self.graphicsOverlay, tapLocation: tapLocation, animated: true)
    }
    
    private func showAlert(message:String) {
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        self.reverseGeocode(mappoint)
    }
}


