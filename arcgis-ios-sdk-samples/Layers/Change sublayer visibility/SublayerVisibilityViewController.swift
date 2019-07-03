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

class SublayerVisibilityViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    private var map: AGSMap!
    private var mapImageLayer: AGSArcGISMapImageLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SublayerVisibilityViewController", "SublayersTableViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: .topographic())
        
        //initialize the map image layer using a url
        let mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!)
        
        //add the image layer to the map
        self.map.operationalLayers.add(mapImageLayer)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 6e6, spatialReference: .webMercator()), scale: 9e7)
        
        //store the map image layer for later use
        self.mapImageLayer = mapImageLayer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SublayersPopover" {
            //get the destination view controller as BookmarksListViewController
            let controller = segue.destination as! SublayersTableViewController
            if let sublayers = mapImageLayer.mapImageSublayers as? [AGSArcGISMapImageSublayer] {
                controller.sublayers = sublayers
            }
            controller.presentationController?.delegate = self
        }
    }
}

extension SublayerVisibilityViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
