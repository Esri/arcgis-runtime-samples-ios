//
// Copyright © 2020 Esri.
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

class EditFeaturesWithFeatureLinkedAnnotationViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            
        }
    }
    
    func makeMap() -> AGSMap {
        let geodatabase = AGSGeodatabase(fileURL: <#T##URL#>)
        let map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: 39.0204, longitude: -77.4159, levelOfDetail: 18)
        map.operationalLayers.add(<#T##anObject: Any##Any#>)
        return map
    }
}
