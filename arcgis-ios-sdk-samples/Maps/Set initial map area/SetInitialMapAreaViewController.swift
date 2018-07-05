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

class SetInitialMapAreaViewController: UIViewController {

    @IBOutlet weak var mapView:AGSMapView!
    var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SetInitialMapAreaViewController"]
        
        //initialize the map with imagery basemap
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        
        //set initial map area
        let envelope = AGSEnvelope(xMin: -12211308.778729, yMin: 4645116.003309, xMax: -12208257.879667, yMax: 4650542.535773, spatialReference: AGSSpatialReference(wkid: 102100))
        self.map.initialViewpoint = AGSViewpoint(targetExtent: envelope)

        //assign the map to the map view
        self.mapView.map = map
        
    }
}
