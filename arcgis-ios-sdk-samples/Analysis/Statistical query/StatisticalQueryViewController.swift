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

class StatisticalQueryViewController: UIViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private var visualEffectView:UIVisualEffectView!
    @IBOutlet private var getStatisticsButton: UIButton!
    @IBOutlet private var onlyInCurrentExtentSwitch: UISwitch!
    @IBOutlet private var onlyBigCitiesSwitch: UISwitch!
    private var map: AGSMap?
    private var serviceFeatureTable: AGSServiceFeatureTable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StatisticalQueryViewController"]
        
        // Constraint visual effect view to the map view's attribution label
        visualEffectView.bottomAnchor.constraint(equalTo: mapView.attributionTopAnchor, constant:-10.0).isActive = true
        
        // Corner radius for button
        getStatisticsButton.layer.cornerRadius = 10
        
        // Initialize map and set it on map view
        map = AGSMap(basemap: AGSBasemap.streetsVector())
        mapView.map = map

        // Initialize feature table, layer and add it to map
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: serviceFeatureTable!)
        map?.operationalLayers.add(featureLayer)
    }
}

