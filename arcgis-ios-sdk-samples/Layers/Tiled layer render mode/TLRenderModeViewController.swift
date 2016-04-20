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

class TLRenderModeViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    
    private var map:AGSMap!
    private var tiledLayerBasemap:AGSArcGISTiledLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TLRenderModeViewController"]
        
        //intialize the tiledLayer basemap with topographic basemap
        //we will be changing the rendering mode of this basemap
        self.tiledLayerBasemap = AGSArcGISTiledLayer(URL: NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer")!)
        
        //initialize map using the basemap we just created
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: self.tiledLayerBasemap))
        
        //create a viewpoint from lat, long, scale
        let viewpoint = AGSViewpoint(latitude: 47.606726, longitude: -122.335564, scale: 144447.638572)
        
        //set inital viewpoint
        self.map.initialViewpoint = viewpoint
        
        //assign the map to the map view
        self.mapView.map = self.map
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func valueChanged(sender:UISegmentedControl) {
        //switch the render mode based on selection
        if sender.selectedSegmentIndex == 0 {
            self.tiledLayerBasemap.renderMode = .Scale
        }
        else {
            self.tiledLayerBasemap.renderMode = .Aesthetics
        }
    }
}
