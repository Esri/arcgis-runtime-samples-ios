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
            mapView.map = AGSMap(basemapType: .lightGrayCanvas, latitude: 55.882436, longitude: -2.725610, levelOfDetail: 13)
            
            // create a feature layer
            let featureServiceURL = "https://services1.arcgis.com/6677msI40mnLuuLr/arcgis/rest/services/East_Lothian_Rivers/FeatureServer/0"
            let featureTable = AGSServiceFeatureTable(url: URL(string: featureServiceURL)!)
            let riverFeatureLayer = AGSFeatureLayer(featureTable: featureTable)
            // add the feature layer to the operational layers
            mapView.map?.operationalLayers.add(riverFeatureLayer)
            
            // create an annotation layer
            let riverFeatureLayerURL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/RiversAnnotation/FeatureServer/0"
            let annotationLayer = AGSAnnotationLayer(url: URL(string: riverFeatureLayerURL)!)
            mapView.map?.operationalLayers.add(annotationLayer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayAnnotationViewController"]
    }
}
