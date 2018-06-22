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

class MapRotationViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var slider:UISlider!
    @IBOutlet private weak var rotationLabel:UILabel!
    @IBOutlet private weak var compassButton:UIButton!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapRotationViewController"]
        
        //instantiate map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.streets())
        
        //assign map to the map view
        self.mapView.map = self.map
        
        //update the slider value when the user rotates by pinching
        self.mapView.viewpointChangedHandler = { [weak self] () in
            DispatchQueue.main.async {
                self?.mapViewpointDidChange()
            }
        }

        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -13044000, yMin: 3855000, xMax: -13040000, yMax: 3858000, spatialReference: AGSSpatialReference.webMercator()))
    }
    
    func mapViewpointDidChange() {
        slider.value = Float(mapView.rotation)
        rotationLabel.text = "\(Int(slider.value))\u{00B0}"
        compassButton.transform = CGAffineTransform(rotationAngle: CGFloat(-mapView.rotation * Double.pi / 180))
    }
    
    //MARK: - Actions
    
    //rotate the map view based on the value of the slider
    @IBAction private func sliderValueChanged(_ slider:UISlider) {
        if let viewpoint = self.mapView.currentViewpoint(with: AGSViewpointType.centerAndScale) {
            let rotatedViewpoint = AGSViewpoint(center: viewpoint.targetGeometry as! AGSPoint, scale: viewpoint.targetScale, rotation: Double(slider.value))
            self.mapView.setViewpoint(rotatedViewpoint)
        }
    }
    
    @IBAction private func compassAction() {
        self.compassButton.transform = CGAffineTransform.identity
        self.mapView.setViewpointRotation(0, completion: nil)
    }
}
