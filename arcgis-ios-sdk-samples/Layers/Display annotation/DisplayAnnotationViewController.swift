// Copyright 2020 Esri.
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

class DisplayAnnotationViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            // Assign the map to the map view.
            mapView.map = makeMap()
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapType: .lightGrayCanvas, latitude: 55.882436, longitude: -2.725610, levelOfDetail: 13)
        
        // Create a feature layer.
        let featureServiceURL = URL(string: "https://services1.arcgis.com/6677msI40mnLuuLr/arcgis/rest/services/East_Lothian_Rivers/FeatureServer/0")!
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL)
        let riverFeatureLayer = AGSFeatureLayer(featureTable: featureTable)

        // Create an annotation layer.
        let riverFeatureLayerURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/RiversAnnotation/FeatureServer/0")!
        let annotationLayer = AGSAnnotationLayer(url: riverFeatureLayerURL)
        
        // Add both layers to the operational layers.
        map.operationalLayers.add(riverFeatureLayer)
        map.operationalLayers.add(annotationLayer)
        
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayAnnotationViewController"]
    }
}
