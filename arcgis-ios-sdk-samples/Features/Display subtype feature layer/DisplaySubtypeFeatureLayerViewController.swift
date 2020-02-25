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
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsNightVector())
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -9812691.11079696, yMin: 5128687.20710657, xMax: -9812377.9447607, yMax: 5128865.36767282, spatialReference: .webMercator()))

        // Create a subtype feature layer from a service feature table.
        let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/100")
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL!)
        subtypeFeatureLayer = AGSSubtypeFeatureLayer(featureTable: featureTable)
        subtypeFeatureLayer?.scaleSymbols = false
        map.operationalLayers.add(subtypeFeatureLayer!)
        return map
    }
    
    var subtypeFeatureLayer: AGSSubtypeFeatureLayer? {
        didSet {
            if let subtype = subtypeFeatureLayer {
                subtype.load(completion: { [ weak self ] (_: Error?) in
                    let subtypeSublayer = subtype.sublayer(withName: "Street Light")
                    subtypeSublayer?.labelsEnabled = true
//                    subtypeSublayer?.labelDefinitions.
//                    let labelJSONObject: [String: Any]
//                    subtypeSublayer?.labelDefinitions.append(AGSLabelDefinition.fromJSON(labelJSONObject))

                    let labelJSONObject: [String: Any] = [
                        "labelExpression": "[nominalvoltage]",
                        "labelPlacement": "esriServerPointLabelPlacementAboveRight",
                        "useCodedValues": "true",
                        "symbol": {
                            "angle": 0,
                            "backgroundColor": [0,0,0,0],
                            "borderLineColor": [0,0,0,0],
                            "borderLineSize": 0,
                            "color": [0,0,255,255],
                            "font": {
                                "decoration": "none",
                                "size": 10.5,
                                "style": "normal",
                                "weight": "normal"
                            },
                            "haloColor": [255,255,255,255],
                            "haloSize": 2,
                            "horizontalAlignment": "center",
                            "kerning": "false",
                            "type": "esriTS",
                            "verticalAlignment": "middle",
                            "xoffset": 0,
                            "yoffset": 0
                        }
                    ]
                })
            }
        }
    }
    
    override func viewDidLoad() {
           super.viewDidLoad()
           //add the source code button item to the right of navigation bar
           (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplaySubtypeFeatureLayer", "DisplaySubtypeSettingsViewController"]
   }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? DisplaySubtypeSettingsViewController {
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.map = mapView?.map
            controller.mapScale = mapView.mapScale
            controller.presentationController?.delegate = self
        }
    }
}

extension DisplaySubtypeFeatureLayerViewController: DisplaySubtypeSettingsViewControllerDelegate {
    func displaySubtypeSettingsViewControllerDidChangeMapScale(_ controller: DisplaySubtypeSettingsViewController) {
        mapView.setViewpointScale(controller.mapScale)
    }
    
    func displaySubtypeSettingsViewControllerDidFinish(_ controller: DisplaySubtypeSettingsViewController) {
        dismiss(animated: true)
    }
}

extension DisplaySubtypeFeatureLayerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
