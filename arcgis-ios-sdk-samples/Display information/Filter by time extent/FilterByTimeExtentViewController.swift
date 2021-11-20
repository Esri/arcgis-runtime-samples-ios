// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS
import ArcGISToolkit

class FilterByTimeExtentViewController: UIViewController {
    /// The map view.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let map = makeMap()
            mapView.map = map
            // Set the map view's viewpoint.
            let center = AGSPoint(x: -58.495293, y: 29.979774, spatialReference: .wgs84())
            mapView.setViewpoint(AGSViewpoint(center: center, scale: 1.5e8))
        }
    }
    
    /// The time slider from the ArcGIS toolkit.
    let timeSlider: TimeSlider = {
        let timeSlider = TimeSlider()
        timeSlider.playbackInterval = 0.5
        return timeSlider
    }()
    
    func makeMap() -> AGSMap {
        let featureLayer = AGSFeatureLayer(
            item: AGSPortalItem(
                portal: .arcGISOnline(withLoginRequired: false),
                itemID: "49925d814d7e40fb8fa64864ef62d55e"
            ),
            layerID: 0
        )
        initializeTimeSlider(for: featureLayer)
        
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        map.operationalLayers.add(featureLayer)
        return map
    }
    
    /// Initialize the time steps.
    func initializeTimeSlider(for featureLayer: AGSFeatureLayer) {
        // The default date and time for the starting and ending thumb.
        let currentTimeExtent: AGSTimeExtent = {
            // The date formatter.
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return AGSTimeExtent(
                startTime: formatter.date(from: "2005/10/01 05:00")!,
                endTime: formatter.date(from: "2005/10/31 05:00")!
            )
        }()
        featureLayer.load { [weak self] error in
            guard let self = self, error == nil, let fullTimeExtent = featureLayer.fullTimeExtent else { return }
            self.timeSlider.initializeTimeSteps(timeStepCount: 60, fullExtent: fullTimeExtent) { _ in
                // Set the current time extent.
                self.timeSlider.currentExtent = currentTimeExtent
            }
        }
    }

    /// Configure the time slider's attributes and position.
    func setupTimeSlider() {
        // Configure time slider.
        timeSlider.labelMode = .thumbs
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(timeSlider:)), for: .valueChanged)
        // Add the time slider to the view.
        view.addSubview(timeSlider)
        
        // Add constraints to position the slider.
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        // Assign the constraints.
        let constraints = [
            timeSlider.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: timeSlider.trailingAnchor, multiplier: 1),
            mapView.attributionTopAnchor.constraint(equalToSystemSpacingBelow: timeSlider.bottomAnchor, multiplier: 1)
        ]
        // Activate the constraints.
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc
    func timeSliderValueChanged(timeSlider: TimeSlider) {
        if mapView.timeExtent != timeSlider.currentExtent {
            mapView.timeExtent = timeSlider.currentExtent
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTimeSlider()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["FilterByTimeExtentViewController"]
    }
}
