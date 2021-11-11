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
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
        }
    }
    
    /// The date formatter.
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    
    /// The data's start date.
    let startTime = formatter.date(from: "2005/9/1 05:00")!
    /// The data's end date.
    let endTime = formatter.date(from: "2005/12/31 05:00")!
    /// The default date and time for the starting thumb.
    let currentStartTime = formatter.date(from: "2005/10/01 05:00")
    /// The default date and time for the ending thumb.
    let currentEndTime = formatter.date(from: "2005/10/31 05:00")
    
    /// The feature table URL tracking hurricanes in 2005.
    static let featureTableURL = URL(string: "https://services5.arcgis.com/N82JbI5EYtAkuUKU/ArcGIS/rest/services/Hurricane_time_enabled_layer_2005_1_day/FeatureServer/0")!
    
    /// The feature layer made from the feature table.
    let featureLayer = AGSFeatureLayer(
        featureTable: AGSServiceFeatureTable(
            url: featureTableURL
        )
    )
    
    /// The time slider from the ArcGIS toolkit.
    let timeSlider = TimeSlider()
    
    /// Configure the time slider's attributes and position.
    func setupTimeSlider() {
        // Configure time slider.
        timeSlider.labelMode = .thumbs
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(timeSlider:)), for: .valueChanged)
        // Add the time slider to the view.
        view.addSubview(timeSlider)
        
        // Add constraints to position the slider.
        let margin: CGFloat = 10.0
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        // Set the time slider on top of the attribution bar in the map view.
        timeSlider.bottomAnchor.constraint(equalTo: mapView.attributionTopAnchor, constant: -margin).isActive = true
        // Set the side constraints with padding for the time slider .
        timeSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin).isActive = true
        timeSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin).isActive = true
    }
    
    /// Initialize the time slider's steps.
    func initializeTimeStepsFromQuery() {
        featureLayer.load { [unowned self] error in
            guard error == nil else { fatalError(error!.localizedDescription) }
            populateFeaturesWithQuery { _ in
                timeSlider.initializeTimeSteps(timeStepCount: 200, fullExtent: AGSTimeExtent(startTime: startTime, endTime: endTime)) { _ in
                    // Show the time slider.
                    timeSlider.currentExtent = AGSTimeExtent(startTime: currentStartTime, endTime: currentEndTime)
                    
                    mapView.map!.operationalLayers.add(featureLayer)
                }
            }
        }
    }
    
    /// Populate the features using the requested time extent.
    func populateFeaturesWithQuery(completion: @escaping (AGSFeatureQueryResult) -> Void) {
        let featureTable = featureLayer.featureTable as! AGSServiceFeatureTable
        // Create query parameters.
        let queryParams = AGSQueryParameters()
        // Create a new time extent that covers the desired interval.
        let timeExtent = AGSTimeExtent(startTime: startTime, endTime: endTime)
        
        // Apply the time extent to query parameters to filter features based on time.
        queryParams.timeExtent = timeExtent
        // Set the feature request mode to load the features faster.
        featureTable.featureRequestMode = .manualCache
        // Populate features based on query parameters.
        featureTable.populateFromService(with: queryParams, clearCache: true, outFields: ["*"]) { (result: AGSFeatureQueryResult?, error: Error?) in
            guard error == nil else { return }
            if let result = result {
                completion(result)
            }
        }
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
        initializeTimeStepsFromQuery()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["FilterByTimeExtentViewController"]
    }
}
