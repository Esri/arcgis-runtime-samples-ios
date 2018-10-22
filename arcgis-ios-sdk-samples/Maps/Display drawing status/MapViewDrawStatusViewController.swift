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

class MapViewDrawStatusViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var activityIndicatorView:UIView!
    
    private var map:AGSMap?
    /// The observation of the map view's draw status.
    private var drawStatusObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapViewDrawStatusViewController"]
        
        //instantiate the map with topographic basemap
        self.map = AGSMap(basemap: .topographic())
        
        //initial viewpoint
        self.map?.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -13639984, yMin: 4537387, xMax: -13606734, yMax: 4558866, spatialReference: AGSSpatialReference.webMercator()))
        
        //add a feature layer
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.map?.operationalLayers.add(featureLayer)
        
        //assign the map to mapView
        self.mapView.map = self.map
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        drawStatusObservation = mapView.observe(\.drawStatus, options: .initial) { [weak self] (mapView, _) in
            DispatchQueue.main.async {
                self?.activityIndicatorView.isHidden = mapView.drawStatus == .completed
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        drawStatusObservation = nil
    }
}
