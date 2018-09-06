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

class MILShowLegendViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var legendBBI:UIBarButtonItem!
    
    private var map:AGSMap!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    private var popover:UIPopoverPresentationController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MILShowLegendViewController", "MILLegendTableViewController"]
        
        //initialize the map
        self.map = AGSMap(basemap: .topographic())
        
        //create tiled layer
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer")!)
        self.map.operationalLayers.add(tiledLayer)
        
        //create a map image layer using a url
        self.mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        //add the image layer to the map
        self.map.operationalLayers.add(self.mapImageLayer)
        
        //create feature table using a url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0")!)
        //create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        //add feature layer to the map
        self.map.operationalLayers.add(featureLayer)
        
        self.map.load { [weak self] (error:Error?) -> Void in
            if error == nil {
                self?.legendBBI.isEnabled = true
            }
        }
        
        self.mapView.map = self.map
        
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 6e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LegendTableSegue" {
            let controller = segue.destination as! MILLegendTableViewController
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.operationalLayers = self.map.operationalLayers
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
