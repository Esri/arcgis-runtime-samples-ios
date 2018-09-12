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

class ShowMagnifierViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate map with topographic basemap
        self.map = AGSMap(basemap: .imagery())
        
        //asssign map to the map view
        self.mapView.map = self.map
        
        //enable magnifier
        self.mapView.interactionOptions.isMagnifierEnabled = true
        
        //zoom to custom viewpoint
        let viewpoint = AGSViewpoint(center: AGSPoint(x: -110.8258 , y: 32.1545089, spatialReference: AGSSpatialReference.wgs84()), scale: 2e4)
        self.mapView.setViewpoint(viewpoint)
        
        //setup source code BBI
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowMagnifierViewController"]
    }
    
}
