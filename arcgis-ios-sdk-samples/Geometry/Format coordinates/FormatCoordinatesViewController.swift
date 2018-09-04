// Copyright 2017 Esri.
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

class FormatCoordinatesViewController: UIViewController, AGSGeoViewTouchDelegate, UITextFieldDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var latLongDDTextField:UITextField!
    @IBOutlet private var latLongDMSTextField:UITextField!
    @IBOutlet private var utmTextField:UITextField!
    @IBOutlet private var usngTextField:UITextField!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FormatCoordinatesViewController"]
        
        //initializer map with basemap
        let map = AGSMap(basemap: .imagery())
        
        //assign map to map view
        self.mapView.map = map
        
        //add graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //touch delegate for map view
        self.mapView.touchDelegate = self
        
        //initial point
        let point = AGSPoint(x: 0, y: 0, spatialReference: AGSSpatialReference.webMercator())
        
        //add initial graphic
        self.displayGraphicAtPoint(point)
        
        //coordinate notation for the initial point
        self.coordinateStringsFromPoint(point)
    }
    
    //use AGSCoordinateFormatter to generate coordinate string for the given point
    private func coordinateStringsFromPoint(_ point: AGSPoint) {
        
        self.latLongDDTextField.text = AGSCoordinateFormatter.latitudeLongitudeString(from: point, format: .decimalDegrees, decimalPlaces: 4)
        
        self.latLongDMSTextField.text = AGSCoordinateFormatter.latitudeLongitudeString(from: point, format: .degreesMinutesSeconds, decimalPlaces: 1)
        
        self.utmTextField.text = AGSCoordinateFormatter.utmString(from: point, conversionMode: .latitudeBandIndicators, addSpaces: true)
        
        self.usngTextField.text = AGSCoordinateFormatter.usngString(from: point, precision: 4, addSpaces: true)
    }
    
    private func displayGraphicAtPoint(_ point:AGSPoint) {
        
        //remove previous graphic from graphics overlay
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //add graphic at tapped location
        let symbol = AGSSimpleMarkerSymbol(style: .cross, color: .yellow, size: 20)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        self.graphicsOverlay.graphics.add(graphic)
    }
    
    //MARK: - UITextFieldDelegate
    
    //user can change any of the string and update the location by tapping return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let text = textField.text else {
            return true
        }
        
        var point:AGSPoint?
        
        //using tags on the textfield to differentiate
        switch textField.tag {
        case 0, 1:
            point = AGSCoordinateFormatter.point(fromLatitudeLongitudeString: text, spatialReference: self.mapView.spatialReference)
        case 2:
            point = AGSCoordinateFormatter.point(fromUTMString: text, spatialReference: self.mapView.spatialReference, conversionMode: AGSUTMConversionMode.latitudeBandIndicators)
        case 3:
            point = AGSCoordinateFormatter.point(fromUSNGString: text, spatialReference: self.mapView.spatialReference)
        default:
            break
        }
        
        //if a new point is generated, update the graphic on map
        //and update other textfields
        if point != nil {
            self.displayGraphicAtPoint(point!)
            
            self.coordinateStringsFromPoint(point!)
        }
        
        //hide keyboard
        textField.resignFirstResponder()
        
        return true
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //display graphic at the tapped location
        self.displayGraphicAtPoint(mapPoint)
        
        //populate the coordinate strings for tapped location
        self.coordinateStringsFromPoint(mapPoint)
    }

}
