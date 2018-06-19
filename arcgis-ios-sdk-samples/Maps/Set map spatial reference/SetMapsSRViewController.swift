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

class SetMapsSRViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SetMapsSRViewController"]
        
        //initialize the map, spatial reference as world bonne (54024) or goode (54052)
        self.map = AGSMap(spatialReference: AGSSpatialReference(wkid: 54024)!)
        
        
        //Adding a map image layer which can reproject itself to the map's spatial reference
        //Note: Some layer such as tiled layer cannot reproject and will fail to draw if their spatial 
        //reference is not the same as the map's spatial reference
        self.map.operationalLayers.add(AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!))
        
        //assing the map to the map view
        self.mapView.map = self.map
    }

}
