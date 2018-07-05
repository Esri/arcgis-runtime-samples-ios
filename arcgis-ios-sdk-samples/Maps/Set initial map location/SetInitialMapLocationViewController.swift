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

class SetInitialMapLocationViewController: UIViewController {

    @IBOutlet weak var mapView:AGSMapView!
    var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SetInitialMapLocationViewController"]
        
        //initialize map with `imagery with labels` basemap and an initial location
        self.map = AGSMap(basemapType: .imageryWithLabels, latitude: -33.867886, longitude: -63.985, levelOfDetail: 16)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
    }

}
