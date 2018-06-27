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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapViewDrawStatusViewController"]
        
        //instantiate the map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
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
        
        //add observer for drawStatus on mapView
        //so we can show/hide an indicator when the status change
        mapView.addObserver(self, forKeyPath: #keyPath(AGSGeoView.drawStatus), options: .initial, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.activityIndicatorView.isHidden = strongSelf.mapView.drawStatus == .completed
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        mapView.removeObserver(self, forKeyPath: #keyPath(AGSGeoView.drawStatus))
    }
}
