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

class OpenStreetMapLayerViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with an OpenStreetMap basemap
        let map = AGSMap(basemapType: .openStreetMap, latitude: 34.056295, longitude: -117.195800, levelOfDetail: 10)
        //assign the map to the map view
        mapView.map = map
    
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OpenStreetMapLayerViewController"]
    }
    
}
