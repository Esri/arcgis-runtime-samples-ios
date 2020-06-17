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

class ShowPopupViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            //set touch delegate
            mapView.touchDelegate = self
        }
    }
    
    var featureLayer: AGSFeatureLayer?
    var popupsViewController: AGSPopupsViewController?
    
    func makeMap() -> AGSMap {
        let mapURL = URL(string: "https://runtime.maps.arcgis.com/home/item.html?id=ccf828425b5a456b90eb75cf72278e13")!
        let map = AGSMap(url: mapURL)
        map?.initialViewpoint = AGSViewpoint(latitude: 47.607042, longitude: -122.324304, scale: 15)
//        let featureServiceURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Seattle_Downtown_Features/FeatureServer/4")!
//        let featureTable = AGSServiceFeatureTable(url: featureServiceURL)
//        featureLayer = AGSFeatureLayer(featureTable: featureTable)
//        map?.operationalLayers.add(featureLayer!)
        let b = map?.operationalLayers[0] as! AGSLayer
        print(b.name)
        return map!
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.mapView.identifyLayer(featureLayer!, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            if let error = result.error {
                self?.presentAlert(error: error)
            } else {
                if result.popups.isEmpty {
                    print("EMPTY")
                }
                self?.popupsViewController = AGSPopupsViewController(popups: result.popups)
//                self?.popupsViewController?.delegate = self
                
                self!.present(self!.popupsViewController!, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowPopupViewController"]
    }
}
