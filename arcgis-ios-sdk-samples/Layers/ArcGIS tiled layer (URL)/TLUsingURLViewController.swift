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

class TLUsingURLViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a tiledLayer using url to a map server
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://services.arcgisonline.com/arcgis/rest/services/NatGeo_World_Map/MapServer")!)
        
        //initialize the map and add the tiled layer as an operational layer
        self.map = AGSMap()
        self.map.operationalLayers.add(tiledLayer)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TLUsingURLViewController"]
    }
    
}
