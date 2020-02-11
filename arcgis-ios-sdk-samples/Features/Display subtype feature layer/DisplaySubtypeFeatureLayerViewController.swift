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

class DisplaySubtypeFeatureLayerViewController: UIViewController {
    
//    @IBAction private weak var sublayerSwitch: UISwitch!
    
    var subtypeFeatureLayer: AGSSubtypeFeatureLayer? {
        didSet {
            if let subtype = subtypeFeatureLayer {
                subtype.load(completion: {[weak self](_: Error?) in
                    let subtypeSublayer = subtype.sublayer(withName: "Street Light")
                    subtypeSublayer?.labelsEnabled = true
                    // subtypeSublayer?.labelDefinitions.
                    // still have to get labels?
                    
                    let originalRednerer = subtypeSublayer?.renderer
                    
                    let symbol = AGSSimpleMarkerSymbol(style: .diamond, color: .systemPink, size: 20)
                    let alternativeRenderer = AGSSimpleRenderer(symbol: symbol)
                })
            }
        }
    }

    @IBAction func showSublayer(_ sender: UISwitch) {
        if sender.isOn {
            subtypeFeatureLayer?.isVisible = true
        }
        else {
            subtypeFeatureLayer?.isVisible = false
        }
    }
    
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            // initialize the map
            mapView.map = AGSMap(basemap: .streetsNightVector())
            mapView.map?.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -9812691.11079696, yMin: 5128687.20710657, xMax: -9812377.9447607, yMax: 5128865.36767282, spatialReference: .webMercator()))
            
            // on any navigation on the map view

            // create a subtype feature layer from a service feature table
            let featureServiceURL = URL(string:"https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/100")
            let featureTable = AGSServiceFeatureTable(url: featureServiceURL!)
            subtypeFeatureLayer = AGSSubtypeFeatureLayer(featureTable: featureTable)
            mapView.map?.operationalLayers.add(subtypeFeatureLayer as Any)
            
        }
    }
    
    
    
    
    override func viewDidLoad() {
           super.viewDidLoad()
           //add the source code button item to the right of navigation bar
           (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplaySubtypeFeatureLayer"]
   }
}

extension DisplaySubtypeFeatureLayerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
