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

class ManageMapLayersViewController: UIViewController, MMLLayersViewControllerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var map:AGSMap!
    
    private var deletedLayers:[AGSLayer]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
        let imageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
        self.map.operationalLayers.add(imageLayer)
        
        let tiledLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        self.map.operationalLayers.add(tiledLayer)

        self.deletedLayers = [AGSLayer]()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ManageMapLayersViewController", "MMLLayersViewController"]
        
        self.mapView.map = map
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -133e5, y: 45e5, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 2e7))
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LayersSegue" {
            
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.viewControllers[0] as! MMLLayersViewController
            controller.layers = self.map.operationalLayers
            controller.deletedLayers = self.deletedLayers
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            controller.delegate = self
        }
    }
    
    //MARK: - MMLLayersViewControllerDelegate
    
    func layersViewControllerWantsToClose(_ layersViewController: MMLLayersViewController, withDeletedLayers layers: [AGSLayer]) {
        self.deletedLayers = layers
        self.dismiss(animated: true, completion: nil)
    }
}
