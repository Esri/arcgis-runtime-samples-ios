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

class ManageMapLayersViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    private var allLayers: [AGSLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "ManageMapLayersViewController",
            "MMLLayersViewController"
        ]
                
        let map = AGSMap(basemap: .topographic())
        
        let imageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
        map.operationalLayers.add(imageLayer)
        
        let tiledLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        map.operationalLayers.add(tiledLayer)
        
        allLayers = [imageLayer, tiledLayer]
        
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -133e5, y: 45e5, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 2e7))
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? MMLLayersViewController {
            
            controller.operationalLayers = mapView.map?.operationalLayers
            controller.allLayers = allLayers
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            navController.presentationController?.delegate = self
        }
    }

}

extension ManageMapLayersViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}
