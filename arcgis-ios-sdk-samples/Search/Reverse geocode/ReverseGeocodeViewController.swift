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

class ReverseGeocodeViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            // Create an instance of a map with ESRI topographic basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.touchDelegate = self
            
            // Add the graphics overlay.
            mapView.graphicsOverlays.add(self.graphicsOverlay)
            
            // Zoom to a specific extent.
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -117.195, y: 34.058, spatialReference: .wgs84()), scale: 5e4))
        }
    }
    
    private var locatorTask = AGSLocatorTask(url: URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var cancelable: AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ReverseGeocodeViewController"]
    }
    
    private func reverseGeocode(_ point: AGSPoint) {
        // Cancel previous request.
        if self.cancelable != nil {
            self.cancelable.cancel()
        }
        
        // Hide the callout.
        self.mapView.callout.dismiss()
        
        // Remove already existing graphics.
        self.graphicsOverlay.graphics.removeAllObjects()
        
        // Normalize point.
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point) as! AGSPoint
        
        let graphic = self.graphicForPoint(normalizedPoint)
        self.graphicsOverlay.graphics.add(graphic)
        
        // Initialize parameters.
        let reverseGeocodeParameters = AGSReverseGeocodeParameters()
        reverseGeocodeParameters.maxResults = 1
        // Reverse geocode.
        self.cancelable = self.locatorTask.reverseGeocode(withLocation: normalizedPoint, parameters: reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) in
            if let error = error as NSError? {
                // Present user canceled error.
                if error.code != NSUserCancelledError {
                    self?.presentAlert(error: error)
                }
            } else if let result = results?.first {
                graphic.attributes.addEntries(from: result.attributes!)
                self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint)
                return
            } else {
                self?.presentAlert(message: "No address found")
            }
            self?.graphicsOverlay.graphics.remove(graphic)
        }
    }
    
    /// Method returns a graphic object for the specified point and attributes.
    private func graphicForPoint(_ point: AGSPoint) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: [String: AnyObject]())
        return graphic
    }
    
    /// Show callout for the graphic.
    private func showCalloutForGraphic(_ graphic: AGSGraphic, tapLocation: AGSPoint) {
        // Get the attributes from the graphic and populates the title and detail for the callout.
        let cityString = graphic.attributes["City"] as? String ?? ""
        let addressString = graphic.attributes["Address"] as? String ?? ""
        let stateString = graphic.attributes["State"] as? String ?? ""
        self.mapView.callout.title = addressString
        self.mapView.callout.detail = "\(cityString) \(stateString)"
        self.mapView.callout.isAccessoryButtonHidden = true
        self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: true)
    }

    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.reverseGeocode(mapPoint)
    }
}
