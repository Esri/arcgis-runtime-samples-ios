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
    
    /// Every layer on the map or that could be added to the map.
    private var allLayers: [AGSLayer] = []
    
    /// The layers present in `allLayers` but not in the map's `operationalLayers`.
    private var removedLayers: [AGSLayer] {
        if let operationalLayers = mapView?.map?.operationalLayers as? [AGSLayer] {
            return allLayers.filter { !operationalLayers.contains($0) }
        }
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "ManageMapLayersViewController",
            "MMLLayersViewController"
        ]
                
        let map = AGSMap(basemap: .topographic())
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -133e5, y: 45e5, spatialReference: .webMercator()), scale: 2e7)
        
        let elevationImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
        let censusTiledLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        
        allLayers = [elevationImageLayer, censusTiledLayer]
        
        // load all the layers into the map to start
        map.operationalLayers.addObjects(from: allLayers)
        
        mapView.map = map
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? MMLLayersViewController {
            // convert and assign the map's operational layers as a Swift array
            controller.map = mapView?.map
            controller.allLayers = allLayers
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            navController.presentationController?.delegate = self
        }
    }
}

extension ManageMapLayersViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
