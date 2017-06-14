//
// Copyright 2017 Esri.
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
//

import UIKit
import ArcGIS

class RasterLayerVC: UIViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!

    private var map:AGSMap!
    
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterLayerVC"]
        
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using raster
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        //initialize map with raster layer as the basemap
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        
        self.mapView.map = map
        
        self.mapView.map?.operationalLayers.add(rasterLayer!)
        
        self.rasterLayer.addObserver(self, forKeyPath: "loadStatus", options: .new, context: nil)
        
    }

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if self.rasterLayer.loadStatus == AGSLoadStatus.loaded {
            self.mapView.setViewpoint(AGSViewpoint(center: (self.rasterLayer.fullExtent?.center)!, scale: 80000))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
