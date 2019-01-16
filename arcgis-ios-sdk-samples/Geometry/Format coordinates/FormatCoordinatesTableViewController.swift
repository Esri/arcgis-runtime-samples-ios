// Copyright 2018 Esri.
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

class FormatCoordinatesTableViewController: UITableViewController {
    @IBOutlet private var latLongDDTextField: UITextField?
    @IBOutlet private var latLongDMSTextField: UITextField?
    @IBOutlet private var utmTextField: UITextField?
    @IBOutlet private var usngTextField: UITextField?
    
    var changeHandler: ((AGSPoint) -> Void)?
    
    var point: AGSPoint? {
        didSet {
            updateCoordinateFieldsForPoint()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateCoordinateFieldsForPoint()
    }
    
    //use AGSCoordinateFormatter to generate coordinate string for the given point
    private func updateCoordinateFieldsForPoint() {
        guard let point = point else {
            return
        }
        
        latLongDDTextField?.text = AGSCoordinateFormatter.latitudeLongitudeString(from: point, format: .decimalDegrees, decimalPlaces: 4)
        
        latLongDMSTextField?.text = AGSCoordinateFormatter.latitudeLongitudeString(from: point, format: .degreesMinutesSeconds, decimalPlaces: 1)
        
        utmTextField?.text = AGSCoordinateFormatter.utmString(from: point, conversionMode: .latitudeBandIndicators, addSpaces: true)
        
        usngTextField?.text = AGSCoordinateFormatter.usngString(from: point, precision: 4, addSpaces: true)
    }
    
    @IBAction func textFieldAction(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        let newPoint: AGSPoint? = {
            switch sender {
            case latLongDDTextField, latLongDMSTextField:
                return AGSCoordinateFormatter.point(fromLatitudeLongitudeString: text, spatialReference: point?.spatialReference)
            case utmTextField:
                return AGSCoordinateFormatter.point(fromUTMString: text, spatialReference: point?.spatialReference, conversionMode: .latitudeBandIndicators)
            case usngTextField:
                return AGSCoordinateFormatter.point(fromUSNGString: text, spatialReference: point?.spatialReference)
            default:
                return nil
            }
        }()
        
        if let newPoint = newPoint {
            point = newPoint
            // fire the handler
            changeHandler?(newPoint)
        } else {
            // invalid input, reset the fields
            updateCoordinateFieldsForPoint()
        }
    }
}

extension FormatCoordinatesTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
