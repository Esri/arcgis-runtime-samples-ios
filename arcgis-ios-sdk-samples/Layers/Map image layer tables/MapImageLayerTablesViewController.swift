// Copyright 2022 Esri.
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
//

import UIKit
import ArcGIS

class MapImageLayerTablesViewController: UIViewController {
    
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISStreets)
        }
    }
    
    static let serviceRequestURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/ServiceRequest/MapServer")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [ "MapImageLayerTablesViewController"]
    }
}
